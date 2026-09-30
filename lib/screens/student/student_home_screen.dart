import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/error_handler.dart';
import '../../models/actionable_meal_group.dart';
import '../../models/meal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/response_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/meal_card.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final groupsAsync = ref.watch(actionableMealGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Waste Reduction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authNotifierProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentProfileProvider);
          ref.invalidate(actionableMealGroupsProvider);
          ref.invalidate(upcomingMealsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Header Profile Card
              profileAsync.when(
                data: (profile) {
                  final name = profile?.fullName.isNotEmpty == true
                      ? profile!.fullName
                      : 'Student';
                  final rollNo = profile?.rollNumber ?? 'Roll No N/A';
                  final courseName =
                      profile?.course?.name ?? profile?.course?.code ?? 'Course';
                  final yearLabel =
                      profile?.studyYear?.label ?? 'Year';

                  return Card(
                    color: const Color(0xFF15803D),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $name 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rollNo,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$courseName • $yearLabel',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: LoadingView(message: 'Loading profile...'),
                  ),
                ),
                error: (err, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading profile: ${ErrorHandler.getFriendlyErrorMessage(err)}'),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Advance Meal Planning Section
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No upcoming meals scheduled',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Find the next actionable group, or fallback to first group
                  ActionableMealGroup targetGroup;
                  try {
                    targetGroup = groups.firstWhere((g) => g.isNextActionable);
                  } catch (_) {
                    targetGroup = groups.first;
                  }

                  final otherGroups =
                      groups.where((g) => g.mealDate != targetGroup.mealDate).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Meal Day Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  targetGroup.formatDisplayDate(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  targetGroup.isActionable
                                      ? 'Active Planning Day'
                                      : 'Responses Closed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: targetGroup.isActionable
                                        ? const Color(0xFF15803D)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: targetGroup.isActionable
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: targetGroup.isActionable
                                    ? Colors.green.shade200
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  targetGroup.isActionable
                                      ? Icons.edit_calendar_rounded
                                      : Icons.lock_clock_outlined,
                                  size: 14,
                                  color: targetGroup.isActionable
                                      ? const Color(0xFF15803D)
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  targetGroup.isActionable ? 'Open' : 'Closed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: targetGroup.isActionable
                                        ? const Color(0xFF15803D)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (targetGroup.earliestDeadline != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: Color(0xFF92400E),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Response deadline: ${targetGroup.formatEarliestDeadline()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Meals for Target Actionable Day
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: targetGroup.meals.length,
                        itemBuilder: (context, index) {
                          final meal = targetGroup.meals[index];
                          return _StudentMealItemCard(meal: meal);
                        },
                      ),

                      // Other Upcoming Meal Dates
                      if (otherGroups.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        const Text(
                          'Later Upcoming Menus',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View upcoming meal options. Advance selections will open after earlier deadlines pass.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...otherGroups.map((group) {
                          return _UpcomingDateExpansionCard(group: group);
                        }),
                      ],
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: LoadingView(message: 'Loading advance meal schedule...'),
                ),
                error: (err, _) => ErrorView(
                  message: ErrorHandler.getFriendlyErrorMessage(err),
                  onRetry: () => ref.invalidate(actionableMealGroupsProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentMealItemCard extends ConsumerWidget {
  final Meal meal;

  const _StudentMealItemCard({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsesAsync = ref.watch(userMealResponsesProvider(meal.id));
    final isClosed = meal.isDeadlinePassed;

    return responsesAsync.when(
      data: (responses) {
        final hasResponded = responses.isNotEmpty;

        Widget? badge;
        if (hasResponded) {
          badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 13, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text(
                  'Responded',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          );
        } else if (isClosed) {
          badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Closed',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          );
        } else {
          badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Text(
              'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          );
        }

        final actionLabel = isClosed
            ? 'View Choices'
            : (hasResponded ? 'Edit Preferences' : 'Select Preferences');

        return MealCard(
          meal: meal,
          actionLabel: actionLabel,
          trailingBadge: badge,
          onTap: () {
            context.push('/student/meal/${meal.id}');
          },
        );
      },
      loading: () => MealCard(
        meal: meal,
        actionLabel: isClosed ? 'View Choices' : 'Select Preferences',
        onTap: () {
          context.push('/student/meal/${meal.id}');
        },
      ),
      error: (err, _) => MealCard(
        meal: meal,
        actionLabel: isClosed ? 'View Choices' : 'Select Preferences',
        onTap: () {
          context.push('/student/meal/${meal.id}');
        },
      ),
    );
  }
}

class _UpcomingDateExpansionCard extends StatelessWidget {
  final ActionableMealGroup group;

  const _UpcomingDateExpansionCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        title: Text(
          group.formatDisplayDate(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          '${group.meals.length} meals scheduled',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        children: group.meals.map((meal) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: _StudentMealItemCard(meal: meal),
          );
        }).toList(),
      ),
    );
  }
}
