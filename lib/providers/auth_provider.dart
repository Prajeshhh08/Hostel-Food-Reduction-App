import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_provider.dart';
import 'supabase_provider.dart';

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final authService = ref.watch(authServiceProvider);
  final sessionUser = authState.asData?.value.session?.user;
  if (sessionUser != null) return sessionUser;
  return authService.currentUser;
});

class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signIn(
        email: email,
        password: password,
      );
      // Invalidate currentProfileProvider to immediately trigger profile fetch
      ref.invalidate(currentProfileProvider);
      state = const AsyncValue.data(null);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<AuthResponse?> signUpStudent({
    required String email,
    required String password,
    required String fullName,
    required String rollNumber,
    required int courseId,
    required int studyYearId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signUpStudent(
        email: email,
        password: password,
        fullName: fullName,
        rollNumber: rollNumber,
        courseId: courseId,
        studyYearId: studyYearId,
      );
      ref.invalidate(currentProfileProvider);
      state = const AsyncValue.data(null);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      ref.invalidate(currentProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<void>>(AuthNotifier.new);
