class WasteStatistic {
  final DateTime mealDate;
  final int mealsLogged;
  final double preparedPortions;
  final double servedPortions;
  final double wastedPortions;
  final double wastePercentage;

  const WasteStatistic({
    required this.mealDate,
    required this.mealsLogged,
    required this.preparedPortions,
    required this.servedPortions,
    required this.wastedPortions,
    required this.wastePercentage,
  });

  factory WasteStatistic.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['meal_date'] is String) {
      parsedDate = DateTime.tryParse(json['meal_date'] as String) ?? DateTime.now();
    } else if (json['meal_date'] is DateTime) {
      parsedDate = json['meal_date'] as DateTime;
    } else {
      parsedDate = DateTime.now();
    }

    return WasteStatistic(
      mealDate: parsedDate,
      mealsLogged: (json['meals_logged'] as num?)?.toInt() ?? 0,
      preparedPortions:
          (json['prepared_portions'] as num?)?.toDouble() ?? 0.0,
      servedPortions: (json['served_portions'] as num?)?.toDouble() ?? 0.0,
      wastedPortions: (json['wasted_portions'] as num?)?.toDouble() ?? 0.0,
      wastePercentage:
          (json['waste_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meal_date':
          '${mealDate.year.toString().padLeft(4, '0')}-${mealDate.month.toString().padLeft(2, '0')}-${mealDate.day.toString().padLeft(2, '0')}',
      'meals_logged': mealsLogged,
      'prepared_portions': preparedPortions,
      'served_portions': servedPortions,
      'wasted_portions': wastedPortions,
      'waste_percentage': wastePercentage,
    };
  }
}
