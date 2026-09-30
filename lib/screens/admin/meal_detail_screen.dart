import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/error_handler.dart';
import '../../models/course.dart';
import '../../models/study_year.dart';
import '../../models/waste_log.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/course_year_demand_card.dart';
import '../../widgets/course_year_filter.dart';
import '../../widgets/error_view.dart';
import '../../widgets/food_demand_card.dart';
import '../../widgets/food_prediction_card.dart';
import '../../widgets/loading_view.dart';

class MealDetailScreen extends ConsumerStatefulWidget {
  final int mealId;

  const MealDetailScreen({super.key, required this.mealId});

  @override
  ConsumerState<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends ConsumerState<MealDetailScreen> {
  int? _selectedCourseId;
  int? _selectedStudyYearId;

  bool get _isFiltered =>
      _selectedCourseId != null || _selectedStudyYearId != null;

  String _getScopeLabel(
    List<Course>? courses,
    List<StudyYear>? studyYears,
  ) {
    String courseName = 'All Courses';
    if (_selectedCourseId != null && courses != null) {
      final match = courses.where((c) => c.id == _selectedCourseId).firstOrNull;
      if (match != null) {
        courseName = match.code;
      }
    }

    String yearName = 'All Years';
    if (_selectedStudyYearId != null && studyYears != null) {
      final match =
          studyYears.where((y) => y.id == _selectedStudyYearId).firstOrNull;
      if (match != null) {
        yearName = match.label;
      }
    }

    return '$courseName • $yearName';
  }

  void _refreshData() {
    ref.invalidate(mealDetailProvider(widget.mealId));
    ref.invalidate(foodPredictionProvider(widget.mealId));
    ref.invalidate(mealWasteLogProvider(widget.mealId));
    if (_isFiltered) {
      ref.invalidate(
        courseYearDemandProvider(
          CourseYearDemandFilter(
            mealId: widget.mealId,
            courseId: _selectedCourseId,
            studyYearId: _selectedStudyYearId,
          ),
        ),
      );
    } else {
      ref.invalidate(mealFoodDemandProvider(widget.mealId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealAsync = ref.watch(mealDetailProvider(widget.mealId));
    final coursesAsync = ref.watch(coursesListProvider);
    final studyYearsAsync = ref.watch(studyYearsListProvider);
    final wasteLogAsync = ref.watch(mealWasteLogProvider(widget.mealId));

    final courses = coursesAsync.asData?.value;
    final studyYears = studyYearsAsync.asData?.value;
    final scopeLabel = _getScopeLabel(courses, studyYears);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demand & Preparation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh All',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Info Header
              mealAsync.when(
                data: (meal) {
                  if (meal == null) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Meal not found'),
                      ),
                    );
                  }
                  final foodItemsSummary = meal.mealItems.isNotEmpty
                      ? meal.mealItems
                          .map((item) => item.foodItem?.name ?? 'Item')
                          .join(' + ')
                      : meal.menuName;

                  return Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                meal.displayIcon,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal.displayName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (meal.menuName.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      meal.menuName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (foodItemsSummary.isNotEmpty &&
                              foodItemsSummary != meal.menuName) ...[
                            const Divider(height: 20),
                            Text(
                              foodItemsSummary,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: LoadingView(message: 'Loading meal info...'),
                  ),
                ),
                error: (e, s) => ErrorView(
                  message: ErrorHandler.getFriendlyErrorMessage(e),
                  onRetry: () => ref.invalidate(mealDetailProvider(widget.mealId)),
                ),
              ),

              const SizedBox(height: 16),

              // Filter Dropdown Widget
              CourseYearFilterWidget(
                coursesAsync: coursesAsync,
                studyYearsAsync: studyYearsAsync,
                selectedCourseId: _selectedCourseId,
                selectedStudyYearId: _selectedStudyYearId,
                onCourseChanged: (val) {
                  setState(() {
                    _selectedCourseId = val;
                  });
                },
                onStudyYearChanged: (val) {
                  setState(() {
                    _selectedStudyYearId = val;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Section 1: Food Demand (Filtered/Overall)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FOOD DEMAND',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scopeLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isFiltered
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isFiltered
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFiltered
                              ? Icons.filter_alt_rounded
                              : Icons.public_rounded,
                          size: 14,
                          color: _isFiltered
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isFiltered ? 'Filtered' : 'Overall',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isFiltered
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Demand List (Filtered vs Overall)
              if (!_isFiltered)
                _buildOverallDemandList(ref)
              else
                _buildFilteredDemandList(ref, scopeLabel),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Section 2: Explainable Food Preparation Recommendation
              const Text(
                'PREPARATION RECOMMENDATION',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Explainable food quantity recommendation based on total student demand and historical attendance adjustment.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 14),

              _buildPredictionList(ref),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Section 3: Meal Waste Record
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MEAL WASTE RECORD',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  wasteLogAsync.when(
                    data: (log) => log != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF86EFAC),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Color(0xFF15803D),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Recorded',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildWasteStatusCard(wasteLogAsync),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWasteStatusCard(AsyncValue<WasteLog?> wasteLogAsync) {
    return wasteLogAsync.when(
      data: (log) {
        if (log != null) {
          return Card(
            color: const Color(0xFFF8FAFC),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prepared: ${log.preparedPortions.toInt()}  |  Served: ${log.servedPortions.toInt()}  |  Wasted: ${log.wastedPortions.toInt()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  if (log.actualAttendanceCount != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Actual Attendance: ${log.actualAttendanceCount} students',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.push('/admin/waste/${widget.mealId}');
                        ref.invalidate(mealWasteLogProvider(widget.mealId));
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('View / Edit Waste Record'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No waste record has been entered yet.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      await context.push('/admin/waste/${widget.mealId}');
                      ref.invalidate(mealWasteLogProvider(widget.mealId));
                    },
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('Log Meal Waste'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: LoadingView(message: 'Checking waste status...'),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Unable to load waste status: ${ErrorHandler.getFriendlyErrorMessage(e)}'),
        ),
      ),
    );
  }

  Widget _buildOverallDemandList(WidgetRef ref) {
    final demandAsync = ref.watch(mealFoodDemandProvider(widget.mealId));

    return demandAsync.when(
      data: (demandItems) {
        if (demandItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36.0),
              child: Column(
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No food responses yet.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Students haven't submitted their preferences for this meal.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: demandItems.length,
          itemBuilder: (context, index) {
            final item = demandItems[index];
            return FoodDemandCard(demand: item);
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 36.0),
        child: LoadingView(message: 'Loading overall demand...'),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load food demand.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ErrorHandler.getFriendlyErrorMessage(err),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        ref.invalidate(mealFoodDemandProvider(widget.mealId)),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredDemandList(WidgetRef ref, String scopeLabel) {
    final filter = CourseYearDemandFilter(
      mealId: widget.mealId,
      courseId: _selectedCourseId,
      studyYearId: _selectedStudyYearId,
    );
    final demandAsync = ref.watch(courseYearDemandProvider(filter));

    return demandAsync.when(
      data: (demandItems) {
        if (demandItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36.0),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No responses found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'There are no food preferences recorded for:\n$scopeLabel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: demandItems.length,
          itemBuilder: (context, index) {
            final item = demandItems[index];
            return CourseYearDemandCard(
              demand: item,
              showScopeBadge:
                  _selectedCourseId == null || _selectedStudyYearId == null,
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 36.0),
        child: LoadingView(message: 'Filtering demand...'),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load filtered demand.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ErrorHandler.getFriendlyErrorMessage(err),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => ref.invalidate(courseYearDemandProvider(filter)),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionList(WidgetRef ref) {
    final predictionAsync = ref.watch(foodPredictionProvider(widget.mealId));

    return predictionAsync.when(
      data: (predictions) {
        if (predictions.isEmpty ||
            predictions.every((p) => p.confirmedWantCount == 0)) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.soup_kitchen_outlined,
                    size: 44,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No student demand data yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Students need to submit their meal preferences before a preparation recommendation can be calculated.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            final prediction = predictions[index];
            return FoodPredictionCard(prediction: prediction);
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 36.0),
        child: LoadingView(message: 'Calculating food preparation recommendations...'),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to calculate food recommendation.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ErrorHandler.getFriendlyErrorMessage(err),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        ref.invalidate(foodPredictionProvider(widget.mealId)),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
