import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_year_demand.dart';
import '../models/food_prediction.dart';
import '../models/meal_food_demand.dart';
import '../models/waste_log.dart';
import '../models/waste_statistic.dart';
import 'supabase_provider.dart';

/// Provider for overall food demand of a specific meal using RPC `get_meal_food_demand`
final mealFoodDemandProvider =
    FutureProvider.family<List<MealFoodDemand>, int>((ref, mealId) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return dashboardService.getMealFoodDemand(mealId);
});

/// Filter parameters for Course & Year Demand RPC
class CourseYearDemandFilter {
  final int mealId;
  final int? courseId;
  final int? studyYearId;

  const CourseYearDemandFilter({
    required this.mealId,
    this.courseId,
    this.studyYearId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseYearDemandFilter &&
          runtimeType == other.runtimeType &&
          mealId == other.mealId &&
          courseId == other.courseId &&
          studyYearId == other.studyYearId;

  @override
  int get hashCode =>
      mealId.hashCode ^ (courseId?.hashCode ?? 0) ^ (studyYearId?.hashCode ?? 0);
}

/// Provider for filtered food demand by course/year using RPC `get_meal_demand_by_course_year`
final courseYearDemandProvider =
    FutureProvider.family<List<CourseYearDemand>, CourseYearDemandFilter>(
        (ref, filter) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return dashboardService.getDemandByCourseYear(
    mealId: filter.mealId,
    courseId: filter.courseId,
    studyYearId: filter.studyYearId,
  );
});

/// Provider for explainable food preparation predictions using RPC `predict_meal_food_quantity`
final foodPredictionProvider =
    FutureProvider.family<List<FoodPrediction>, int>((ref, mealId) async {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return dashboardService.getFoodPredictions(mealId);
});

/// Provider for a specific meal's waste log
final mealWasteLogProvider =
    FutureProvider.family<WasteLog?, int>((ref, mealId) async {
  final wasteService = ref.watch(wasteServiceProvider);
  return wasteService.getWasteLogForMeal(mealId);
});

/// Provider for 7-day waste statistics using RPC `get_waste_statistics`
final wasteStatisticsProvider =
    FutureProvider.family<List<WasteStatistic>, int>((ref, days) async {
  final wasteService = ref.watch(wasteServiceProvider);
  return wasteService.getWasteStatistics(days: days);
});

final wasteLogsProvider = FutureProvider<List<WasteLog>>((ref) async {
  final wasteService = ref.watch(wasteServiceProvider);
  return wasteService.getWasteLogs();
});

final weeklyWasteLogsProvider = FutureProvider<List<WasteLog>>((ref) async {
  final wasteService = ref.watch(wasteServiceProvider);
  return wasteService.getWeeklyWasteLogs();
});

class WasteLogNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> createWasteLog({
    required int mealId,
    required double preparedPortions,
    required double servedPortions,
    required double wastedPortions,
    int? actualAttendanceCount,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final wasteService = ref.read(wasteServiceProvider);
      await wasteService.createWasteLog(
        mealId: mealId,
        preparedPortions: preparedPortions,
        servedPortions: servedPortions,
        wastedPortions: wastedPortions,
        actualAttendanceCount: actualAttendanceCount,
        notes: notes,
      );
      ref.invalidate(mealWasteLogProvider(mealId));
      ref.invalidate(wasteStatisticsProvider(7));
      ref.invalidate(wasteLogsProvider);
      ref.invalidate(weeklyWasteLogsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateWasteLog({
    required int mealId,
    required int wasteLogId,
    required double preparedPortions,
    required double servedPortions,
    required double wastedPortions,
    int? actualAttendanceCount,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final wasteService = ref.read(wasteServiceProvider);
      await wasteService.updateWasteLog(
        wasteLogId: wasteLogId,
        preparedPortions: preparedPortions,
        servedPortions: servedPortions,
        wastedPortions: wastedPortions,
        actualAttendanceCount: actualAttendanceCount,
        notes: notes,
      );
      ref.invalidate(mealWasteLogProvider(mealId));
      ref.invalidate(wasteStatisticsProvider(7));
      ref.invalidate(wasteLogsProvider);
      ref.invalidate(weeklyWasteLogsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final wasteLogNotifierProvider =
    NotifierProvider<WasteLogNotifier, AsyncValue<void>>(WasteLogNotifier.new);
