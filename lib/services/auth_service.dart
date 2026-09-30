import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  User? get currentUser {
    try {
      return _supabase.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Session? get currentSession {
    try {
      return _supabase.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUpStudent({
    required String email,
    required String password,
    required String fullName,
    required String rollNumber,
    required int courseId,
    required int studyYearId,
  }) async {
    debugPrint('AUTH: signup started for $email');
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'roll_number': rollNumber.trim().toUpperCase(),
        'course_id': courseId,
        'study_year_id': studyYearId,
      },
    );
    debugPrint('AUTH: signup response session=${response.session != null} user=${response.user?.id}');
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('AUTH: login started for $email');
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    debugPrint('AUTH: login succeeded user=${response.user?.id}');
    debugPrint('AUTH: currentUser=${currentUser?.id}');
    return response;
  }

  Future<void> signOut() async {
    debugPrint('AUTH: signing out user=${currentUser?.id}');
    await _supabase.auth.signOut();
    debugPrint('AUTH: signout completed');
  }
}
