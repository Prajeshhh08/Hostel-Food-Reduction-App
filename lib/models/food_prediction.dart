class FoodPrediction {
  final int foodItemId;
  final String foodName;
  final double portionGrams;
  final int confirmedWantCount;
  final double historicalNoShowRate;
  final double expectedDemand;
  final int recommendedPortions;
  final double recommendedGrams;

  const FoodPrediction({
    required this.foodItemId,
    required this.foodName,
    required this.portionGrams,
    required this.confirmedWantCount,
    required this.historicalNoShowRate,
    required this.expectedDemand,
    required this.recommendedPortions,
    required this.recommendedGrams,
  });

  bool get hasHistoricalData => historicalNoShowRate > 0;

  String get formattedQuantity {
    if (recommendedGrams >= 1000) {
      final kg = recommendedGrams / 1000;
      String text = kg.toStringAsFixed(2);
      if (text.contains('.')) {
        text = text.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      return '$text kg';
    } else {
      return '${recommendedGrams.toStringAsFixed(0)} g';
    }
  }

  factory FoodPrediction.fromJson(Map<String, dynamic> json) {
    return FoodPrediction(
      foodItemId: (json['food_item_id'] as num).toInt(),
      foodName: json['food_name'] as String? ?? '',
      portionGrams: (json['portion_grams'] as num?)?.toDouble() ?? 0.0,
      confirmedWantCount: (json['confirmed_want_count'] as num?)?.toInt() ?? 0,
      historicalNoShowRate:
          (json['historical_no_show_rate'] as num?)?.toDouble() ?? 0.0,
      expectedDemand: (json['expected_demand'] as num?)?.toDouble() ?? 0.0,
      recommendedPortions:
          (json['recommended_portions'] as num?)?.toInt() ?? 0,
      recommendedGrams:
          (json['recommended_grams'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_item_id': foodItemId,
      'food_name': foodName,
      'portion_grams': portionGrams,
      'confirmed_want_count': confirmedWantCount,
      'historical_no_show_rate': historicalNoShowRate,
      'expected_demand': expectedDemand,
      'recommended_portions': recommendedPortions,
      'recommended_grams': recommendedGrams,
    };
  }
}
