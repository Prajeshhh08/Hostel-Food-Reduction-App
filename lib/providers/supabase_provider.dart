import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/meal_service.dart';
import '../services/menu_service.dart';
import '../services/profile_service.dart';
import '../services/response_service.dart';
import '../services/waste_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileService(client);
});

final mealServiceProvider = Provider<MealService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MealService(client);
});

final menuServiceProvider = Provider<MenuService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MenuService(client);
});

final responseServiceProvider = Provider<ResponseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ResponseService(client);
});

final wasteServiceProvider = Provider<WasteService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WasteService(client);
});

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DashboardService(client);
});
