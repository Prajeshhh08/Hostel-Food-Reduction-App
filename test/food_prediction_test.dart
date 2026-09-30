import 'package:flutter_test/flutter_test.dart';
import 'package:foodwaste_reduction/models/food_prediction.dart';

void main() {
  group('FoodPrediction Model Tests', () {
    test('Correctly deserializes JSON response from predict_meal_food_quantity RPC', () {
      final json = {
        'food_item_id': 1,
        'food_name': 'Rice',
        'portion_grams': 200.0,
        'confirmed_want_count': 102,
        'historical_no_show_rate': 0.06,
        'expected_demand': 95.88,
        'recommended_portions': 96,
        'recommended_grams': 19200.0,
      };

      final prediction = FoodPrediction.fromJson(json);

      expect(prediction.foodItemId, 1);
      expect(prediction.foodName, 'Rice');
      expect(prediction.portionGrams, 200.0);
      expect(prediction.confirmedWantCount, 102);
      expect(prediction.historicalNoShowRate, 0.06);
      expect(prediction.expectedDemand, 95.88);
      expect(prediction.recommendedPortions, 96);
      expect(prediction.recommendedGrams, 19200.0);
      expect(prediction.hasHistoricalData, isTrue);
      expect(prediction.formattedQuantity, '19.2 kg');
    });

    test('Handles no-history case (historical_no_show_rate = 0)', () {
      final json = {
        'food_item_id': 2,
        'food_name': 'Sambar',
        'portion_grams': 150,
        'confirmed_want_count': 7,
        'historical_no_show_rate': 0,
        'expected_demand': 7.0,
        'recommended_portions': 7,
        'recommended_grams': 1050,
      };

      final prediction = FoodPrediction.fromJson(json);

      expect(prediction.foodItemId, 2);
      expect(prediction.foodName, 'Sambar');
      expect(prediction.hasHistoricalData, isFalse);
      expect(prediction.recommendedPortions, 7);
      expect(prediction.formattedQuantity, '1.05 kg');
    });

    test('Formats gram quantities below 1000g accurately in grams', () {
      final json = {
        'food_item_id': 3,
        'food_name': 'Pickle',
        'portion_grams': 20.0,
        'confirmed_want_count': 15,
        'historical_no_show_rate': 0.0,
        'expected_demand': 15.0,
        'recommended_portions': 15,
        'recommended_grams': 300.0,
      };

      final prediction = FoodPrediction.fromJson(json);

      expect(prediction.formattedQuantity, '300 g');
    });
  });
}
