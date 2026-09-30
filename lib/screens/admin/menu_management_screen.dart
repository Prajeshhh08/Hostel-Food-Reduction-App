import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/error_handler.dart';
import '../../models/meal.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/admin_meal_menu_card.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  String _selectedFilter = 'Next 7 Days';

  String _formatDateHeader(String dateStr) {
    final nowKolkata =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final todayKolkata =
        DateTime.utc(nowKolkata.year, nowKolkata.month, nowKolkata.day);

    final parts = dateStr.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((p) => p == null)) {
      return dateStr;
    }

    final groupDate = DateTime.utc(parts[0]!, parts[1]!, parts[2]!);
    final diffDays = groupDate.difference(todayKolkata).inDays;

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final formatted =
        '${months[parts[1]! - 1]} ${parts[2]!}, ${parts[0]!}';

    if (diffDays == 0) {
      return 'Today • $formatted';
    } else if (diffDays == 1) {
      return 'Tomorrow • $formatted';
    } else {
      return formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(adminUpcomingMealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Create Meal',
            onPressed: () {
              context.push('/admin/menu/create');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/admin/menu/create');
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Meal'),
        backgroundColor: const Color(0xFF15803D),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminUpcomingMealsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter and Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Menus',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'Next 7 Days',
                        child: Text('Next 7 Days'),
                      ),
                      DropdownMenuItem(
                        value: 'Next 14 Days',
                        child: Text('Next 14 Days'),
                      ),
                      DropdownMenuItem(
                        value: 'All Upcoming',
                        child: Text('All Upcoming'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedFilter = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Schedule menus, configure food portions, and response deadlines.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              // Meal List Grouped by Date
              mealsAsync.when(
                data: (meals) {
                  if (meals.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.restaurant_menu_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No upcoming meals scheduled',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a meal to start planning advance menus for students.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () {
                                context.push('/admin/menu/create');
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create First Meal'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Group meals by date
                  final Map<String, List<Meal>> grouped = {};
                  for (final meal in meals) {
                    grouped.putIfAbsent(meal.mealDate, () => []).add(meal);
                  }

                  final sortedDates = grouped.keys.toList()..sort();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final dateStr = sortedDates[index];
                      final dateMeals = grouped[dateStr]!;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatDateHeader(dateStr).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...dateMeals.map((meal) {
                              return AdminMealMenuCard(meal: meal);
                            }),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: LoadingView(message: 'Loading upcoming menus...'),
                ),
                error: (err, _) => ErrorView(
                  message: ErrorHandler.getFriendlyErrorMessage(err),
                  onRetry: () => ref.invalidate(adminUpcomingMealsProvider),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
