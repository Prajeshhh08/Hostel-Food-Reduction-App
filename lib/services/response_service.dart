import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_response.dart';

class ResponseService {
  final SupabaseClient _supabase;

  ResponseService(this._supabase);

  Future<List<FoodResponse>> getCurrentUserResponses({
    required int mealId,
    required String userId,
  }) async {
    final response = await _supabase
        .from('food_responses')
        .select('*, meal_items!inner(meal_id)')
        .eq('user_id', userId)
        .eq('meal_items.meal_id', mealId);

    return (response as List)
        .map((json) => FoodResponse.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveResponses({
    required String userId,
    required Map<int, bool> mealItemResponses, // mealItemId -> wantsFood
  }) async {
    if (mealItemResponses.isEmpty) return;

    final records = mealItemResponses.entries.map((entry) {
      return {
        'meal_item_id': entry.key,
        'user_id': userId,
        'wants_food': entry.value,
        'responded_at': DateTime.now().toIso8601String(),
      };
    }).toList();

    await _supabase.from('food_responses').upsert(
      records,
      onConflict: 'meal_item_id,user_id',
    );
  }

  Future<List<Map<String, dynamic>>> getFoodDemandForMeal({
    required int mealId,
    int? courseId,
    int? studyYearId,
  }) async {
    var query = _supabase
        .from('food_responses')
        .select('meal_item_id, wants_food, meal_items!inner(id, meal_id, food_items(id, name)), profiles!inner(id, course_id, study_year_id)')
        .eq('meal_items.meal_id', mealId);

    if (courseId != null) {
      query = query.eq('profiles.course_id', courseId);
    }
    if (studyYearId != null) {
      query = query.eq('profiles.study_year_id', studyYearId);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response as List);
  }
}
