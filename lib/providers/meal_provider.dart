import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/actionable_meal_group.dart';
import '../models/meal.dart';
import 'supabase_provider.dart';

final todayMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final mealService = ref.watch(mealServiceProvider);
  return mealService.getTodayMeals();
});

final upcomingMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final mealService = ref.watch(mealServiceProvider);
  return mealService.getUpcomingMeals();
});

final actionableMealGroupsProvider =
    FutureProvider<List<ActionableMealGroup>>((ref) async {
  final mealService = ref.watch(mealServiceProvider);
  return mealService.getActionableMealGroups();
});

final nextActionableMealGroupProvider =
    Provider<AsyncValue<ActionableMealGroup?>>((ref) {
  final groupsAsync = ref.watch(actionableMealGroupsProvider);
  return groupsAsync.whenData((groups) {
    if (groups.isEmpty) return null;
    try {
      return groups.firstWhere((g) => g.isNextActionable);
    } catch (_) {
      return groups.first;
    }
  });
});

final mealDetailProvider =
    FutureProvider.family<Meal?, int>((ref, mealId) async {
  final mealService = ref.watch(mealServiceProvider);
  return mealService.getMealWithFoodItems(mealId);
});
