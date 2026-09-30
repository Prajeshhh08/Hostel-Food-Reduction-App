import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodwaste_reduction/models/profile.dart';
import 'package:foodwaste_reduction/providers/auth_provider.dart';
import 'package:foodwaste_reduction/providers/profile_provider.dart';
import 'package:foodwaste_reduction/routing/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Router Authentication & Role Guard Tests', () {
    testWidgets('Unauthenticated user on /login stays on /login', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(
                  const AuthState(AuthChangeEvent.signedOut, null),
                )),
            currentUserProvider.overrideWith((ref) => null),
            currentProfileProvider.overrideWith((ref) => Future.value(null)),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, equals('/login'));
    });

    testWidgets('Unauthenticated user navigating to /register stays on /register (no glitch)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(
                  const AuthState(AuthChangeEvent.signedOut, null),
                )),
            currentUserProvider.overrideWith((ref) => null),
            currentProfileProvider.overrideWith((ref) => Future.value(null)),
            coursesListProvider.overrideWith((ref) => Future.value([])),
            studyYearsListProvider.overrideWith((ref) => Future.value([])),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/register');
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        equals('/register'),
        reason: '/register must remain open for unauthenticated users',
      );
    });

    testWidgets('Unauthenticated user attempting protected /student is redirected to /login', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(
                  const AuthState(AuthChangeEvent.signedOut, null),
                )),
            currentUserProvider.overrideWith((ref) => null),
            currentProfileProvider.overrideWith((ref) => Future.value(null)),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/student');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, equals('/login'));
    });

    testWidgets('Unauthenticated user attempting protected /admin is redirected to /login', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(
                  const AuthState(AuthChangeEvent.signedOut, null),
                )),
            currentUserProvider.overrideWith((ref) => null),
            currentProfileProvider.overrideWith((ref) => Future.value(null)),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/admin');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, equals('/login'));
    });

    testWidgets('Authenticated student on /login is redirected to /student', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const studentUser = User(
        id: 'student-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );
      final mockSession = Session(
        accessToken: 'mock_token',
        tokenType: 'bearer',
        user: studentUser,
      );

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(
                  AuthState(AuthChangeEvent.signedIn, mockSession),
                )),
            currentUserProvider.overrideWith((ref) => studentUser),
            currentProfileProvider.overrideWith((ref) => Future.value(
                  const Profile(
                    id: 'student-123',
                    fullName: 'Student Test',
                    role: 'student',
                  ),
                )),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, equals('/student'));
    });

    testWidgets('Authenticated student on /register is redirected to /student', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const studentUser = User(
        id: 'student-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );
      final mockSession = Session(
        accessToken: 'mock_token',
        tokenType: 'bearer',
        user: studentUser,
      );

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(
                  AuthState(AuthChangeEvent.signedIn, mockSession),
                )),
            currentUserProvider.overrideWith((ref) => studentUser),
            currentProfileProvider.overrideWith((ref) => Future.value(
                  const Profile(
                    id: 'student-123',
                    fullName: 'Student Test',
                    role: 'student',
                  ),
                )),
            coursesListProvider.overrideWith((ref) => Future.value([])),
            studyYearsListProvider.overrideWith((ref) => Future.value([])),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/register');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, equals('/student'));
    });

    testWidgets('Authenticated student on /student is allowed', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const studentUser = User(
        id: 'student-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );
      final mockSession = Session(
        accessToken: 'mock_token',
        tokenType: 'bearer',
        user: studentUser,
      );

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(
                  AuthState(AuthChangeEvent.signedIn, mockSession),
                )),
            currentUserProvider.overrideWith((ref) => studentUser),
            currentProfileProvider.overrideWith((ref) => Future.value(
                  const Profile(
                    id: 'student-123',
                    fullName: 'Student Test',
                    role: 'student',
                  ),
                )),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/student');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, equals('/student'));
    });

    testWidgets('Authenticated student on /admin is redirected to /student', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const studentUser = User(
        id: 'student-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );
      final mockSession = Session(
        accessToken: 'mock_token',
        tokenType: 'bearer',
        user: studentUser,
      );

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(
                  AuthState(AuthChangeEvent.signedIn, mockSession),
                )),
            currentUserProvider.overrideWith((ref) => studentUser),
            currentProfileProvider.overrideWith((ref) => Future.value(
                  const Profile(
                    id: 'student-123',
                    fullName: 'Student Test',
                    role: 'student',
                  ),
                )),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/admin');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, equals('/student'));
    });

    testWidgets('Authenticated staff_admin on /admin is allowed', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const adminUser = User(
        id: 'admin-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );
      final mockSession = Session(
        accessToken: 'mock_token',
        tokenType: 'bearer',
        user: adminUser,
      );

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(
                  AuthState(AuthChangeEvent.signedIn, mockSession),
                )),
            currentUserProvider.overrideWith((ref) => adminUser),
            currentProfileProvider.overrideWith((ref) => Future.value(
                  const Profile(
                    id: 'admin-123',
                    fullName: 'Admin Test',
                    role: 'staff_admin',
                  ),
                )),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/admin');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, equals('/admin'));
    });

    testWidgets('Authenticated staff_admin on /student is redirected to /admin', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const adminUser = User(
        id: 'admin-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );
      final mockSession = Session(
        accessToken: 'mock_token',
        tokenType: 'bearer',
        user: adminUser,
      );

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(
                  AuthState(AuthChangeEvent.signedIn, mockSession),
                )),
            currentUserProvider.overrideWith((ref) => adminUser),
            currentProfileProvider.overrideWith((ref) => Future.value(
                  const Profile(
                    id: 'admin-123',
                    fullName: 'Admin Test',
                    role: 'staff_admin',
                  ),
                )),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/student');
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, equals('/admin'));
    });
  });
}
