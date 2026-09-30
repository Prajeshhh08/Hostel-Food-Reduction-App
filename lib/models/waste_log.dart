import 'meal.dart';

class WasteLog {
  final int? id;
  final int mealId;
  final double preparedPortions;
  final double servedPortions;
  final double wastedPortions;
  final int? actualAttendanceCount;
  final String? notes;
  final String? loggedBy;
  final DateTime? createdAt;
  final Meal? meal;

  const WasteLog({
    this.id,
    required this.mealId,
    required this.preparedPortions,
    required this.servedPortions,
    required this.wastedPortions,
    this.actualAttendanceCount,
    this.notes,
    this.loggedBy,
    this.createdAt,
    this.meal,
  });

  double get wastePercentage {
    if (preparedPortions <= 0) return 0.0;
    return (wastedPortions / preparedPortions) * 100;
  }

  factory WasteLog.fromJson(Map<String, dynamic> json) {
    Meal? mealObj;
    if (json['meals'] != null && json['meals'] is Map<String, dynamic>) {
      mealObj = Meal.fromJson(json['meals'] as Map<String, dynamic>);
    }

    return WasteLog(
      id: (json['id'] as num?)?.toInt(),
      mealId: (json['meal_id'] as num).toInt(),
      preparedPortions:
          (json['prepared_portions'] as num?)?.toDouble() ?? 0.0,
      servedPortions: (json['served_portions'] as num?)?.toDouble() ?? 0.0,
      wastedPortions: (json['wasted_portions'] as num?)?.toDouble() ?? 0.0,
      actualAttendanceCount:
          (json['actual_attendance_count'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      loggedBy: json['logged_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      meal: mealObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'meal_id': mealId,
      'prepared_portions': preparedPortions,
      'served_portions': servedPortions,
      'wasted_portions': wastedPortions,
      'actual_attendance_count': actualAttendanceCount,
      'notes': notes,
      'logged_by': loggedBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
