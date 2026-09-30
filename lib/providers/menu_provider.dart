import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/meal_edit_data.dart';
import 'meal_provider.dart';
import 'supabase_provider.dart';

final adminUpcomingMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final menuService = ref.watch(menuServiceProvider);
  return menuService.getUpcomingMealsForAdmin();
});

final adminFoodItemsProvider = FutureProvider<List<FoodItem>>((ref) async {
  final menuService = ref.watch(menuServiceProvider);
  return menuService.getActiveFoodItems();
});

final mealEditDataProvider =
    FutureProvider.family<MealEditData?, int>((ref, mealId) async {
  final menuService = ref.watch(menuServiceProvider);
  return menuService.getMealForEditing(mealId);
});

class MealCreationNotifier extends Notifier<AsyncValue<Meal?>> {
  @override
  AsyncValue<Meal?> build() {
    return const AsyncValue.data(null);
  }

  Future<Meal> createMeal({
    required String mealDate,
    required String mealType,
    required String menuName,
    required DateTime responseDeadline,
    required List<MealItemEditData> items,
  }) async {
    state = const AsyncValue.loading();
    try {
      final menuService = ref.read(menuServiceProvider);
      final created = await menuService.createMealWithItems(
        mealDate: mealDate,
        mealType: mealType,
        menuName: menuName,
        responseDeadline: responseDeadline,
        items: items,
      );

      // Invalidate relevant providers
      ref.invalidate(adminUpcomingMealsProvider);
      ref.invalidate(todayMealsProvider);
      ref.invalidate(upcomingMealsProvider);
      ref.invalidate(actionableMealGroupsProvider);

      state = AsyncValue.data(created);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final mealCreationNotifierProvider =
    NotifierProvider<MealCreationNotifier, AsyncValue<Meal?>>(
        MealCreationNotifier.new);

class MealEditNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> updateMeal({
    required int mealId,
    required String menuName,
    required DateTime responseDeadline,
    required List<MealItemEditData> currentItems,
    required List<int> itemIdsToDelete,
  }) async {
    state = const AsyncValue.loading();
    try {
      final menuService = ref.read(menuServiceProvider);
      await menuService.updateMealWithItems(
        mealId: mealId,
        menuName: menuName,
        responseDeadline: responseDeadline,
        currentItems: currentItems,
        itemIdsToDelete: itemIdsToDelete,
      );

      // Invalidate relevant providers
      ref.invalidate(adminUpcomingMealsProvider);
      ref.invalidate(mealEditDataProvider(mealId));
      ref.invalidate(mealDetailProvider(mealId));
      ref.invalidate(todayMealsProvider);
      ref.invalidate(upcomingMealsProvider);
      ref.invalidate(actionableMealGroupsProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final mealEditNotifierProvider =
    NotifierProvider<MealEditNotifier, AsyncValue<void>>(
        MealEditNotifier.new);
