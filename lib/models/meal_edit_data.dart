import 'meal.dart';

class MealItemEditData {
  final int? id; // null if newly added in form
  final int foodItemId;
  final String foodName;
  final int portionGrams;
  final bool hasResponses;
  final int responseCount;

  const MealItemEditData({
    this.id,
    required this.foodItemId,
    required this.foodName,
    required this.portionGrams,
    this.hasResponses = false,
    this.responseCount = 0,
  });

  MealItemEditData copyWith({
    int? id,
    int? foodItemId,
    String? foodName,
    int? portionGrams,
    bool? hasResponses,
    int? responseCount,
  }) {
    return MealItemEditData(
      id: id ?? this.id,
      foodItemId: foodItemId ?? this.foodItemId,
      foodName: foodName ?? this.foodName,
      portionGrams: portionGrams ?? this.portionGrams,
      hasResponses: hasResponses ?? this.hasResponses,
      responseCount: responseCount ?? this.responseCount,
    );
  }
}

class MealEditData {
  final Meal meal;
  final List<MealItemEditData> items;
  final bool hasWasteLog;
  final bool isPastMeal;

  const MealEditData({
    required this.meal,
    required this.items,
    required this.hasWasteLog,
    required this.isPastMeal,
  });

  bool get isLocked => hasWasteLog || isPastMeal;
}
