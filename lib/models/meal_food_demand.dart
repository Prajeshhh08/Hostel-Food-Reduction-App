class MealFoodDemand {
  final int foodItemId;
  final String foodName;
  final double portionGrams;
  final int wantsCount;
  final int doesntWantCount;
  final int totalResponses;

  const MealFoodDemand({
    required this.foodItemId,
    required this.foodName,
    required this.portionGrams,
    required this.wantsCount,
    required this.doesntWantCount,
    required this.totalResponses,
  });

  factory MealFoodDemand.fromJson(Map<String, dynamic> json) {
    return MealFoodDemand(
      foodItemId: (json['food_item_id'] as num).toInt(),
      foodName: json['food_name'] as String? ?? '',
      portionGrams: (json['portion_grams'] as num?)?.toDouble() ?? 0.0,
      wantsCount: (json['wants_count'] as num?)?.toInt() ?? 0,
      doesntWantCount: (json['doesnt_want_count'] as num?)?.toInt() ?? 0,
      totalResponses: (json['total_responses'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_item_id': foodItemId,
      'food_name': foodName,
      'portion_grams': portionGrams,
      'wants_count': wantsCount,
      'doesnt_want_count': doesntWantCount,
      'total_responses': totalResponses,
    };
  }
}
