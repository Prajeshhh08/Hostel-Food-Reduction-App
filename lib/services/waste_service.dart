import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/waste_log.dart';
import '../models/waste_statistic.dart';

class WasteService {
  final SupabaseClient _supabase;

  WasteService(this._supabase);

  /// Fetch existing waste log for a specific meal
  Future<WasteLog?> getWasteLogForMeal(int mealId) async {
    try {
      debugPrint('WASTE_SERVICE: Fetching waste log for mealId=$mealId');
      final response = await _supabase
          .from('waste_logs')
          .select('*, meals(*)')
          .eq('meal_id', mealId)
          .maybeSingle();

      if (response == null) return null;
      return WasteLog.fromJson(response);
    } catch (e, st) {
      debugPrint('WASTE_SERVICE ERROR in getWasteLogForMeal: $e\n$st');
      rethrow;
    }
  }

  /// Create a new waste log for a meal
  Future<WasteLog> createWasteLog({
    required int mealId,
    required double preparedPortions,
    required double servedPortions,
    required double wastedPortions,
    int? actualAttendanceCount,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to record waste.');
    }

    final data = {
      'meal_id': mealId,
      'prepared_portions': preparedPortions,
      'served_portions': servedPortions,
      'wasted_portions': wastedPortions,
      'actual_attendance_count': actualAttendanceCount,
      'notes': notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      'logged_by': user.id,
    };

    try {
      debugPrint('WASTE_SERVICE: Creating waste log for mealId=$mealId');
      final response = await _supabase
          .from('waste_logs')
          .insert(data)
          .select('*, meals(*)')
          .single();

      return WasteLog.fromJson(response);
    } on PostgrestException catch (e, st) {
      debugPrint(
        'WASTE_SERVICE PostgrestException:\n'
        '  Code: ${e.code}\n'
        '  Message: ${e.message}\n'
        '  Details: ${e.details}\n'
        '  Hint: ${e.hint}',
      );
      debugPrintStack(stackTrace: st);
      rethrow;
    } catch (e, st) {
      debugPrint('WASTE_SERVICE ERROR in createWasteLog: $e\n$st');
      rethrow;
    }
  }

  /// Update an existing waste log
  Future<WasteLog> updateWasteLog({
    required int wasteLogId,
    required double preparedPortions,
    required double servedPortions,
    required double wastedPortions,
    int? actualAttendanceCount,
    String? notes,
  }) async {
    final data = {
      'prepared_portions': preparedPortions,
      'served_portions': servedPortions,
      'wasted_portions': wastedPortions,
      'actual_attendance_count': actualAttendanceCount,
      'notes': notes?.trim().isNotEmpty == true ? notes!.trim() : null,
    };

    try {
      debugPrint('WASTE_SERVICE: Updating waste log id=$wasteLogId');
      final response = await _supabase
          .from('waste_logs')
          .update(data)
          .eq('id', wasteLogId)
          .select('*, meals(*)')
          .single();

      return WasteLog.fromJson(response);
    } on PostgrestException catch (e, st) {
      debugPrint(
        'WASTE_SERVICE PostgrestException in updateWasteLog:\n'
        '  Code: ${e.code}\n'
        '  Message: ${e.message}\n'
        '  Details: ${e.details}\n'
        '  Hint: ${e.hint}',
      );
      debugPrintStack(stackTrace: st);
      rethrow;
    } catch (e, st) {
      debugPrint('WASTE_SERVICE ERROR in updateWasteLog: $e\n$st');
      rethrow;
    }
  }

  /// Calls RPC `get_waste_statistics(integer)` to fetch aggregated waste statistics over N days.
  Future<List<WasteStatistic>> getWasteStatistics({int days = 7}) async {
    try {
      debugPrint('RPC CALL: get_waste_statistics with p_days=$days');
      final response = await _supabase.rpc(
        'get_waste_statistics',
        params: {'p_days': days},
      );

      debugPrint('RPC RESPONSE get_waste_statistics: $response');

      if (response == null) return [];

      final list = response as List;
      return list
          .map((item) => WasteStatistic.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e, st) {
      debugPrint(
        'WASTE_SERVICE PostgrestException in getWasteStatistics:\n'
        '  Days: $days\n'
        '  Code: ${e.code}\n'
        '  Message: ${e.message}\n'
        '  Details: ${e.details}\n'
        '  Hint: ${e.hint}',
      );
      debugPrintStack(stackTrace: st);
      rethrow;
    } catch (e, st) {
      debugPrint('WASTE_SERVICE ERROR in getWasteStatistics: $e\n$st');
      rethrow;
    }
  }

  Future<List<WasteLog>> getWasteLogs({int limit = 20}) async {
    final response = await _supabase
        .from('waste_logs')
        .select('*, meals(*)')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => WasteLog.fromJson(json)).toList();
  }

  Future<List<WasteLog>> getWeeklyWasteLogs() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final response = await _supabase
        .from('waste_logs')
        .select('*, meals(*)')
        .gte('created_at', sevenDaysAgo.toIso8601String())
        .order('created_at');

    return (response as List).map((json) => WasteLog.fromJson(json)).toList();
  }
}
