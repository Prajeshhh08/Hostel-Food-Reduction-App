import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_year_demand.dart';
import '../models/food_prediction.dart';
import '../models/meal_food_demand.dart';

class DashboardService {
  final SupabaseClient _supabase;

  DashboardService(this._supabase);

  /// Calls RPC `get_meal_food_demand(p_meal_id)` to fetch aggregated food demand for a meal.
  Future<List<MealFoodDemand>> getMealFoodDemand(int mealId) async {
    try {
      debugPrint('RPC CALL: get_meal_food_demand with p_meal_id=$mealId');

      final response = await _supabase.rpc(
        'get_meal_food_demand',
        params: {'p_meal_id': mealId},
      );

      debugPrint('RPC RESPONSE get_meal_food_demand: $response');

      if (response == null) return [];

      final list = response as List;
      return list
          .map((item) => MealFoodDemand.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e, stack) {
      debugPrint(
        'RPC ERROR in get_meal_food_demand:\n'
        '  Meal ID: $mealId\n'
        '  Code: ${e.code}\n'
        '  Message: ${e.message}\n'
        '  Details: ${e.details}\n'
        '  Hint: ${e.hint}',
      );
      debugPrintStack(stackTrace: stack);
      rethrow;
    } catch (e, stack) {
      debugPrint('RPC ERROR in get_meal_food_demand (General): $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  /// Calls RPC `get_meal_demand_by_course_year` to fetch food demand filtered by course and/or year.
  Future<List<CourseYearDemand>> getDemandByCourseYear({
    required int mealId,
    int? courseId,
    int? studyYearId,
  }) async {
    try {
      debugPrint(
        'RPC CALL: get_meal_demand_by_course_year with '
        'p_meal_id=$mealId, p_course_id=$courseId, p_study_year_id=$studyYearId',
      );

      final response = await _supabase.rpc(
        'get_meal_demand_by_course_year',
        params: {
          'p_meal_id': mealId,
          'p_course_id': courseId,
          'p_study_year_id': studyYearId,
        },
      );

      debugPrint('RPC RESPONSE get_meal_demand_by_course_year: $response');

      if (response == null) return [];

      final list = response as List;
      return list
          .map((item) => CourseYearDemand.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e, stack) {
      debugPrint(
        'RPC ERROR in get_meal_demand_by_course_year:\n'
        '  Meal ID: $mealId\n'
        '  Course ID: $courseId\n'
        '  Study Year ID: $studyYearId\n'
        '  Code: ${e.code}\n'
        '  Message: ${e.message}\n'
        '  Details: ${e.details}\n'
        '  Hint: ${e.hint}',
      );
      debugPrintStack(stackTrace: stack);
      rethrow;
    } catch (e, stack) {
      debugPrint('RPC ERROR in get_meal_demand_by_course_year (General): $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  /// Calls RPC `predict_meal_food_quantity(p_meal_id)` to calculate explainable preparation recommendations.
  Future<List<FoodPrediction>> getFoodPredictions(int mealId) async {
    try {
      debugPrint('RPC CALL: predict_meal_food_quantity with p_meal_id=$mealId');

      final response = await _supabase.rpc(
        'predict_meal_food_quantity',
        params: {'p_meal_id': mealId},
      );

      debugPrint('RPC RESPONSE predict_meal_food_quantity: $response');

      if (response == null) return [];

      final list = response as List;
      return list
          .map((item) => FoodPrediction.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e, stack) {
      debugPrint(
        'RPC ERROR in predict_meal_food_quantity:\n'
        '  Meal ID: $mealId\n'
        '  Code: ${e.code}\n'
        '  Message: ${e.message}\n'
        '  Details: ${e.details}\n'
        '  Hint: ${e.hint}',
      );
      debugPrintStack(stackTrace: stack);
      rethrow;
    } catch (e, stack) {
      debugPrint('RPC ERROR in predict_meal_food_quantity (General): $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }
}
