import 'package:flutter_test/flutter_test.dart';
import 'package:foodwaste_reduction/models/meal_food_demand.dart';

void main() {
  group('MealFoodDemand Model Tests', () {
    test('Correctly deserializes JSON response from get_meal_food_demand RPC', () {
      final json = {
        'food_item_id': 1,
        'food_name': 'Rice',
        'portion_grams': 200.0,
        'wants_count': 102,
        'doesnt_want_count': 18,
        'total_responses': 120,
      };

      final demand = MealFoodDemand.fromJson(json);

      expect(demand.foodItemId, 1);
      expect(demand.foodName, 'Rice');
      expect(demand.portionGrams, 200.0);
      expect(demand.wantsCount, 102);
      expect(demand.doesntWantCount, 18);
      expect(demand.totalResponses, 120);
    });

    test('Handles integer and numeric variation in portion_grams and counts', () {
      final json = {
        'food_item_id': 2,
        'food_name': 'Sambar',
        'portion_grams': 150, // int from json
        'wants_count': 96,
        'doesnt_want_count': 24,
        'total_responses': 120,
      };

      final demand = MealFoodDemand.fromJson(json);

      expect(demand.foodItemId, 2);
      expect(demand.foodName, 'Sambar');
      expect(demand.portionGrams, 150.0);
      expect(demand.wantsCount, 96);
      expect(demand.doesntWantCount, 24);
      expect(demand.totalResponses, 120);
    });

    test('Handles zero responses and null portion gracefully', () {
      final json = {
        'food_item_id': 3,
        'food_name': 'Potato Fry',
        'portion_grams': null,
        'wants_count': 0,
        'doesnt_want_count': 0,
        'total_responses': 0,
      };

      final demand = MealFoodDemand.fromJson(json);

      expect(demand.foodItemId, 3);
      expect(demand.foodName, 'Potato Fry');
      expect(demand.portionGrams, 0.0);
      expect(demand.wantsCount, 0);
      expect(demand.doesntWantCount, 0);
      expect(demand.totalResponses, 0);
    });
  });
}
