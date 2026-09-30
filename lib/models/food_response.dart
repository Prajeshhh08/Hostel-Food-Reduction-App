class FoodResponse {
  final int id;
  final int mealItemId;
  final String userId;
  final bool wantsFood;
  final DateTime? respondedAt;

  const FoodResponse({
    required this.id,
    required this.mealItemId,
    required this.userId,
    required this.wantsFood,
    this.respondedAt,
  });

  factory FoodResponse.fromJson(Map<String, dynamic> json) {
    return FoodResponse(
      id: (json['id'] as num).toInt(),
      mealItemId: (json['meal_item_id'] as num).toInt(),
      userId: json['user_id'] as String,
      wantsFood: json['wants_food'] as bool? ?? false,
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal_item_id': mealItemId,
      'user_id': userId,
      'wants_food': wantsFood,
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
    };
  }
}
