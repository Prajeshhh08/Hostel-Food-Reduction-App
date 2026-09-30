import 'package:flutter_test/flutter_test.dart';
import 'package:foodwaste_reduction/core/utils/validators.dart';
import 'package:foodwaste_reduction/models/waste_log.dart';

void main() {
  group('WasteLog Model Tests', () {
    test('Correctly deserializes JSON response from waste_logs table', () {
      final json = {
        'id': 1,
        'meal_id': 5,
        'prepared_portions': 100.0,
        'served_portions': 92.0,
        'wasted_portions': 8.0,
        'actual_attendance_count': 90,
        'notes': 'Some students left early.',
        'logged_by': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'created_at': '2026-09-29T12:00:00.000Z',
      };

      final log = WasteLog.fromJson(json);

      expect(log.id, 1);
      expect(log.mealId, 5);
      expect(log.preparedPortions, 100.0);
      expect(log.servedPortions, 92.0);
      expect(log.wastedPortions, 8.0);
      expect(log.actualAttendanceCount, 90);
      expect(log.notes, 'Some students left early.');
      expect(log.loggedBy, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
      expect(log.wastePercentage, 8.0);
    });

    test('Handles integer numeric variations and null notes/attendance', () {
      final json = {
        'id': 2,
        'meal_id': 6,
        'prepared_portions': 50,
        'served_portions': 45,
        'wasted_portions': 5,
        'actual_attendance_count': null,
        'notes': null,
      };

      final log = WasteLog.fromJson(json);

      expect(log.id, 2);
      expect(log.mealId, 6);
      expect(log.preparedPortions, 50.0);
      expect(log.servedPortions, 45.0);
      expect(log.wastedPortions, 5.0);
      expect(log.actualAttendanceCount, isNull);
      expect(log.notes, isNull);
    });
  });

  group('Waste Input Validation Tests', () {
    test('Valid portions (served + wasted <= prepared)', () {
      final result = Validators.validateWastePortions(
        prepared: 100,
        served: 90,
        wasted: 10,
        attendance: 88,
      );
      expect(result, isNull);
    });

    test('Invalid portions (served + wasted > prepared)', () {
      final result = Validators.validateWastePortions(
        prepared: 100,
        served: 95,
        wasted: 10,
        attendance: 90,
      );
      expect(result, 'Served + wasted portions cannot exceed prepared portions');
    });

    test('Negative prepared portions rejected', () {
      final result = Validators.validateWastePortions(
        prepared: -1,
        served: 0,
        wasted: 0,
      );
      expect(result, 'Prepared portions must be 0 or greater');
    });

    test('Negative attendance rejected', () {
      final result = Validators.validateWastePortions(
        prepared: 100,
        served: 90,
        wasted: 10,
        attendance: -5,
      );
      expect(result, 'Actual attendance must be 0 or greater');
    });
  });
}
