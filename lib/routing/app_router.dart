import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/create_meal_screen.dart';
import '../screens/admin/edit_meal_screen.dart';
import '../screens/admin/meal_detail_screen.dart';
import '../screens/admin/menu_management_screen.dart';
import '../screens/admin/waste_entry_screen.dart';
import '../screens/admin/waste_stats_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/student/meal_response_screen.dart';
import '../screens/student/student_home_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (previous, next) {
      debugPrint('ROUTER: authState event=${next.asData?.value.event}');
      notifyListeners();
    });
    _ref.listen(currentUserProvider, (previous, next) {
      debugPrint('ROUTER: currentUser=${next?.id}');
      notifyListeners();
    });
    _ref.listen(currentProfileProvider, (previous, next) {
      debugPrint('ROUTER: currentProfile role=${next.asData?.value?.role}');
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateChangesProvider);
    final user = _ref.read(currentUserProvider);
    final profileAsync = _ref.read(currentProfileProvider);

    // 1. Determine Auth State
    final isAuthLoading = authState.isLoading && user == null;
    final isLoggedIn = user != null || authState.asData?.value.session != null;

    final location = state.matchedLocation;
    final isPublicRoute = location == '/login' || location == '/register';

    debugPrint(
      'ROUTER: location=$location | isAuthLoading=$isAuthLoading | isLoggedIn=$isLoggedIn | '
      'profileStatus=${profileAsync.isLoading ? "loading" : (profileAsync.hasError ? "error" : "data")} | '
      'role=${profileAsync.asData?.value?.role}',
    );

    // If auth state is still initializing on cold start, wait without redirecting
    if (isAuthLoading) {
      debugPrint('ROUTER: Auth state initializing -> no redirect');
      return null;
    }

    // 2. Unauthenticated user
    if (!isLoggedIn) {
      if (isPublicRoute) {
        debugPrint('ROUTER: Unauthenticated on public route $location -> allowed');
        return null;
      }
      debugPrint('ROUTER: Unauthenticated on protected route $location -> redirecting to /login');
      return '/login';
    }

    // 3. Authenticated user
    final profile = profileAsync.asData?.value;
    final isStaffAdmin = profile?.isStaffAdmin ??
        (user?.userMetadata?['role'] == 'staff_admin' || user?.appMetadata['role'] == 'staff_admin');

    // If on a public route (/login, /register), immediately navigate to the appropriate dashboard
    if (isPublicRoute) {
      final destination = isStaffAdmin ? '/admin' : '/student';
      debugPrint('ROUTER: Authenticated on public route $location -> redirecting to $destination');
      return destination;
    }

    // Role-based route guard once profile is resolved
    if (profile != null) {
      if (profile.isStaffAdmin && location.startsWith('/student')) {
        debugPrint('ROUTER: Staff admin attempted /student -> redirecting to /admin');
        return '/admin';
      }
      if (!profile.isStaffAdmin && location.startsWith('/admin')) {
        debugPrint('ROUTER: Student attempted /admin -> redirecting to /student');
        return '/student';
      }
    }

    debugPrint('ROUTER: Access granted for $location');
    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentHomeScreen(),
        routes: [
          GoRoute(
            path: 'meal/:mealId',
            builder: (context, state) {
              final mealId = int.tryParse(state.pathParameters['mealId'] ?? '') ?? 0;
              return MealResponseScreen(mealId: mealId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'menu',
            builder: (context, state) => const MenuManagementScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateMealScreen(),
              ),
              GoRoute(
                path: ':mealId/edit',
                builder: (context, state) {
                  final mealId =
                      int.tryParse(state.pathParameters['mealId'] ?? '') ?? 0;
                  return EditMealScreen(mealId: mealId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'meal/:mealId',
            builder: (context, state) {
              final mealId = int.tryParse(state.pathParameters['mealId'] ?? '') ?? 0;
              return MealDetailScreen(mealId: mealId);
            },
          ),
          GoRoute(
            path: 'waste/:mealId',
            builder: (context, state) {
              final mealId = int.tryParse(state.pathParameters['mealId'] ?? '') ?? 0;
              return WasteEntryScreen(mealId: mealId);
            },
          ),
          GoRoute(
            path: 'statistics',
            builder: (context, state) => const WasteStatsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
