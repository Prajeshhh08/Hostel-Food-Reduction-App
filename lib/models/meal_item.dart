import 'food_item.dart';

class MealItem {
  final int id;
  final int mealId;
  final int foodItemId;
  final int portionGrams;
  final DateTime? createdAt;
  final FoodItem? foodItem;

  const MealItem({
    required this.id,
    required this.mealId,
    required this.foodItemId,
    this.portionGrams = 0,
    this.createdAt,
    this.foodItem,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    FoodItem? foodItemObj;
    if (json['food_items'] != null && json['food_items'] is Map<String, dynamic>) {
      foodItemObj = FoodItem.fromJson(json['food_items'] as Map<String, dynamic>);
    }

    return MealItem(
      id: (json['id'] as num).toInt(),
      mealId: (json['meal_id'] as num).toInt(),
      foodItemId: (json['food_item_id'] as num).toInt(),
      portionGrams: (json['portion_grams'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      foodItem: foodItemObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal_id': mealId,
      'food_item_id': foodItemId,
      'portion_grams': portionGrams,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
