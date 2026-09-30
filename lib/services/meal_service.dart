import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/actionable_meal_group.dart';
import '../models/meal.dart';
import '../models/meal_item.dart';

class MealService {
  final SupabaseClient _supabase;

  MealService(this._supabase);

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<List<Meal>> getTodayMeals([String? dateStr]) async {
    final queryDate = dateStr ?? _formatDate(DateTime.now());
    debugPrint('MEAL_SERVICE: Fetching meals for date=$queryDate');

    final response = await _supabase
        .from('meals')
        .select('*, meal_items(*, food_items(*))')
        .eq('meal_date', queryDate)
        .order('created_at');

    debugPrint('MEAL RESPONSE: $response');

    return (response as List)
        .map((json) => Meal.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Meal>> getUpcomingMeals({int limitDays = 7}) async {
    final nowKolkata =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final todayStr = _formatDate(nowKolkata);
    debugPrint('MEAL_SERVICE: Fetching upcoming meals starting from $todayStr');

    final response = await _supabase
        .from('meals')
        .select('*, meal_items(*, food_items(*))')
        .gte('meal_date', todayStr)
        .order('meal_date', ascending: true)
        .order('created_at', ascending: true);

    debugPrint('UPCOMING MEALS RESPONSE: $response');

    return (response as List)
        .map((json) => Meal.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActionableMealGroup>> getActionableMealGroups({int limitDays = 7}) async {
    final meals = await getUpcomingMeals(limitDays: limitDays);
    return groupMealsByDate(meals);
  }

  static List<ActionableMealGroup> groupMealsByDate(List<Meal> meals) {
    if (meals.isEmpty) return [];

    final Map<String, List<Meal>> grouped = {};
    for (final meal in meals) {
      grouped.putIfAbsent(meal.mealDate, () => []).add(meal);
    }

    final sortedDates = grouped.keys.toList()..sort();
    final List<ActionableMealGroup> groups = [];
    bool foundNextActionable = false;

    for (final dateStr in sortedDates) {
      final dateMeals = grouped[dateStr]!;
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();

      final isActionable = dateMeals.any((m) => m.isActionable);

      DateTime? earliestDeadline;
      for (final m in dateMeals) {
        if (m.responseDeadline != null && m.isActionable) {
          if (earliestDeadline == null ||
              m.responseDeadline!.isBefore(earliestDeadline)) {
            earliestDeadline = m.responseDeadline;
          }
        }
      }

      final isNext = isActionable && !foundNextActionable;
      if (isNext) {
        foundNextActionable = true;
      }

      groups.add(
        ActionableMealGroup(
          mealDate: dateStr,
          date: date,
          meals: dateMeals,
          isActionable: isActionable,
          earliestDeadline: earliestDeadline,
          isNextActionable: isNext,
        ),
      );
    }

    return groups;
  }

  Future<Meal?> getMealWithFoodItems(int mealId) async {
    debugPrint('MEAL_SERVICE: Fetching meal details for mealId=$mealId');
    final response = await _supabase
        .from('meals')
        .select('*, meal_items(*, food_items(*))')
        .eq('id', mealId)
        .maybeSingle();

    debugPrint('MEAL_DETAIL RESPONSE: $response');

    if (response == null) return null;
    return Meal.fromJson(response);
  }

  Future<List<MealItem>> getMealItems(int mealId) async {
    final response = await _supabase
        .from('meal_items')
        .select('*, food_items(*)')
        .eq('meal_id', mealId)
        .order('created_at');

    return (response as List)
        .map((json) => MealItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
