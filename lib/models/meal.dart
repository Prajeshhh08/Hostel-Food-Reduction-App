import 'meal_item.dart';

class Meal {
  final int id;
  final String mealDate; // 'YYYY-MM-DD'
  final String mealType; // 'breakfast', 'lunch', 'dinner'
  final String menuName;
  final int averagePortionGrams;
  final DateTime? responseDeadline;
  final DateTime? createdAt;
  final List<MealItem> mealItems;

  const Meal({
    required this.id,
    required this.mealDate,
    required this.mealType,
    required this.menuName,
    this.averagePortionGrams = 0,
    this.responseDeadline,
    this.createdAt,
    this.mealItems = const [],
  });

  bool get isDeadlinePassed {
    if (responseDeadline == null) return false;
    return DateTime.now().toUtc().isAfter(responseDeadline!.toUtc());
  }

  bool get isActionable => !isDeadlinePassed;

  String formatDeadlineKolkata() {
    if (responseDeadline == null) return 'No deadline specified';
    final kolkataTime =
        responseDeadline!.toUtc().add(const Duration(hours: 5, minutes: 30));
    final nowKolkata =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

    final todayKolkata =
        DateTime.utc(nowKolkata.year, nowKolkata.month, nowKolkata.day);
    final deadlineDay = DateTime.utc(
        kolkataTime.year, kolkataTime.month, kolkataTime.day);
    final diffDays = deadlineDay.difference(todayKolkata).inDays;

    final hour = kolkataTime.hour;
    final minute = kolkataTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final timeStr = '$formattedHour:$minute $period';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    if (diffDays == 0) {
      return 'Today, $timeStr';
    } else if (diffDays == 1) {
      return 'Tomorrow, $timeStr';
    } else {
      return '${months[kolkataTime.month - 1]} ${kolkataTime.day}, $timeStr';
    }
  }

  String get displayName {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return mealType;
    }
  }

  String get displayIcon {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🍛';
      case 'dinner':
        return '🌙';
      default:
        return '🍽️';
    }
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    List<MealItem> items = [];
    if (json['meal_items'] != null && json['meal_items'] is List) {
      items = (json['meal_items'] as List)
          .map((item) => MealItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Meal(
      id: (json['id'] as num).toInt(),
      mealDate: json['meal_date'] as String? ?? '',
      mealType: json['meal_type'] as String? ?? '',
      menuName: json['menu_name'] as String? ?? '',
      averagePortionGrams:
          (json['average_portion_grams'] as num?)?.toInt() ?? 0,
      responseDeadline: json['response_deadline'] != null
          ? DateTime.tryParse(json['response_deadline'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      mealItems: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal_date': mealDate,
      'meal_type': mealType,
      'menu_name': menuName,
      'average_portion_grams': averagePortionGrams,
      if (responseDeadline != null)
        'response_deadline': responseDeadline!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
