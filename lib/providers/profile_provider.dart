import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../models/profile.dart';
import '../models/study_year.dart';
import 'auth_provider.dart';
import 'supabase_provider.dart';

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    debugPrint('PROFILE_PROVIDER: No authenticated user, profile is null');
    return null;
  }

  debugPrint('PROFILE_PROVIDER: Fetching profile for user=${user.id}');
  final profileService = ref.watch(profileServiceProvider);
  final profile = await profileService.getProfileWithCourseAndYear(user.id);
  debugPrint('PROFILE_PROVIDER: Resolved profile role=${profile?.role} name=${profile?.fullName}');
  return profile;
});

final coursesListProvider = FutureProvider<List<Course>>((ref) async {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getCourses();
});

final studyYearsListProvider = FutureProvider<List<StudyYear>>((ref) async {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getStudyYears();
});
