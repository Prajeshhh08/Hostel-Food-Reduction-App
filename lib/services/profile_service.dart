import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../models/profile.dart';
import '../models/study_year.dart';

class ProfileService {
  final SupabaseClient _supabase;

  ProfileService(this._supabase);

  Future<Profile?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return getProfileWithCourseAndYear(user.id);
  }

  Future<Profile?> getProfileWithCourseAndYear(String userId) async {
    debugPrint('PROFILE: loading profile for $userId');
    try {
      final response = await _supabase
          .from('profiles')
          .select('*, courses(*), study_years(*)')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final profile = Profile.fromJson(response);
        debugPrint('PROFILE: profile found role=${profile.role} name=${profile.fullName}');
        return profile;
      }
    } catch (e) {
      debugPrint('PROFILE: relational query failed, attempting basic query: $e');
    }

    try {
      // Fallback query in case relational join failed (e.g. staff_admin with null course/year or permission)
      final basicResponse = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (basicResponse != null) {
        final profile = Profile.fromJson(basicResponse);
        debugPrint('PROFILE: basic profile found role=${profile.role} name=${profile.fullName}');
        return profile;
      }
    } catch (e, st) {
      debugPrint('PROFILE: Error fetching profile: $e\n$st');
    }

    debugPrint('PROFILE: profile not found for $userId');
    return null;
  }

  Future<List<Course>> getCourses() async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .order('code');

      final list = (response as List)
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .where((course) => course.active)
          .toList();

      return list;
    } catch (e, st) {
      debugPrint('Error fetching courses from Supabase: $e\n$st');
      rethrow;
    }
  }

  Future<List<StudyYear>> getStudyYears() async {
    try {
      final response = await _supabase
          .from('study_years')
          .select()
          .order('year_number');

      return (response as List)
          .map((json) => StudyYear.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('Error fetching study years from Supabase: $e\n$st');
      rethrow;
    }
  }
}
