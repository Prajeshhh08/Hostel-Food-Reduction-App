class CourseYearDemand {
  final int foodItemId;
  final String foodName;
  final int? courseId;
  final String? courseCode;
  final String? courseName;
  final int? studyYearId;
  final String? studyYearLabel;
  final int wantsCount;
  final int doesntWantCount;

  const CourseYearDemand({
    required this.foodItemId,
    required this.foodName,
    this.courseId,
    this.courseCode,
    this.courseName,
    this.studyYearId,
    this.studyYearLabel,
    required this.wantsCount,
    required this.doesntWantCount,
  });

  int get totalResponses => wantsCount + doesntWantCount;

  factory CourseYearDemand.fromJson(Map<String, dynamic> json) {
    return CourseYearDemand(
      foodItemId: (json['food_item_id'] as num).toInt(),
      foodName: json['food_name'] as String? ?? '',
      courseId: (json['course_id'] as num?)?.toInt(),
      courseCode: json['course_code'] as String?,
      courseName: json['course_name'] as String?,
      studyYearId: (json['study_year_id'] as num?)?.toInt(),
      studyYearLabel: json['study_year_label'] as String?,
      wantsCount: (json['wants_count'] as num?)?.toInt() ?? 0,
      doesntWantCount: (json['doesnt_want_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_item_id': foodItemId,
      'food_name': foodName,
      'course_id': courseId,
      'course_code': courseCode,
      'course_name': courseName,
      'study_year_id': studyYearId,
      'study_year_label': studyYearLabel,
      'wants_count': wantsCount,
      'doesnt_want_count': doesntWantCount,
    };
  }
}
