import 'course.dart';
import 'study_year.dart';

class Profile {
  final String id; // uuid
  final String fullName;
  final String role; // 'student' or 'staff_admin'
  final String? rollNumber;
  final int? courseId; // bigint
  final int? studyYearId; // smallint
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined relational data if fetched via Supabase foreign key queries
  final Course? course;
  final StudyYear? studyYear;

  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.rollNumber,
    this.courseId,
    this.studyYearId,
    this.createdAt,
    this.updatedAt,
    this.course,
    this.studyYear,
  });

  bool get isStudent => role == 'student';
  bool get isStaffAdmin => role == 'staff_admin';

  factory Profile.fromJson(Map<String, dynamic> json) {
    Course? courseObj;
    if (json['courses'] != null && json['courses'] is Map<String, dynamic>) {
      courseObj = Course.fromJson(json['courses'] as Map<String, dynamic>);
    }

    StudyYear? studyYearObj;
    if (json['study_years'] != null && json['study_years'] is Map<String, dynamic>) {
      studyYearObj = StudyYear.fromJson(json['study_years'] as Map<String, dynamic>);
    }

    return Profile(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      rollNumber: json['roll_number']?.toString(),
      courseId: (json['course_id'] as num?)?.toInt(),
      studyYearId: (json['study_year_id'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      course: courseObj,
      studyYear: studyYearObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      'roll_number': rollNumber,
      'course_id': courseId,
      'study_year_id': studyYearId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? fullName,
    String? role,
    String? rollNumber,
    int? courseId,
    int? studyYearId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Course? course,
    StudyYear? studyYear,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      rollNumber: rollNumber ?? this.rollNumber,
      courseId: courseId ?? this.courseId,
      studyYearId: studyYearId ?? this.studyYearId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      course: course ?? this.course,
      studyYear: studyYear ?? this.studyYear,
    );
  }
}
