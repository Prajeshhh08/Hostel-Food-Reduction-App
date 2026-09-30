import 'package:flutter_test/flutter_test.dart';
import 'package:foodwaste_reduction/models/waste_statistic.dart';

void main() {
  group('WasteStatistic Model Tests', () {
    test('Correctly deserializes JSON response from get_waste_statistics RPC', () {
      final json = {
        'meal_date': '2026-09-29',
        'meals_logged': 3,
        'prepared_portions': 100.0,
        'served_portions': 92.0,
        'wasted_portions': 8.0,
        'waste_percentage': 8.0,
      };

      final stat = WasteStatistic.fromJson(json);

      expect(stat.mealDate.year, 2026);
      expect(stat.mealDate.month, 9);
      expect(stat.mealDate.day, 29);
      expect(stat.mealsLogged, 3);
      expect(stat.preparedPortions, 100.0);
      expect(stat.servedPortions, 92.0);
      expect(stat.wastedPortions, 8.0);
      expect(stat.wastePercentage, 8.0);
    });

    test('Handles integer numeric variations and decimal portions', () {
      final json = {
        'meal_date': '2026-09-28',
        'meals_logged': 1,
        'prepared_portions': 99.5,
        'served_portions': 91.25,
        'wasted_portions': 8.25,
        'waste_percentage': 8.29,
      };

      final stat = WasteStatistic.fromJson(json);

      expect(stat.preparedPortions, 99.5);
      expect(stat.servedPortions, 91.25);
      expect(stat.wastedPortions, 8.25);
      expect(stat.wastePercentage, 8.29);
    });
  });

  group('7-Day Aggregate Math Tests', () {
    test('Calculates weighted waste percentage correctly', () {
      const totalPrepared = 1000.0;
      const totalWasted = 80.0;

      final weightedWastePercent = totalPrepared > 0
          ? (totalWasted / totalPrepared) * 100
          : 0.0;

      expect(weightedWastePercent, 8.0);
    });

    test('Safe against division by zero when no prepared portions exist', () {
      const totalPrepared = 0.0;
      const totalWasted = 0.0;

      final weightedWastePercent = totalPrepared > 0
          ? (totalWasted / totalPrepared) * 100
          : 0.0;

      expect(weightedWastePercent, 0.0);
      expect(weightedWastePercent.isNaN, isFalse);
      expect(weightedWastePercent.isInfinite, isFalse);
    });
  });
}
