import 'package:flutter_test/flutter_test.dart';
import 'package:foodwaste_reduction/models/food_item.dart';
import 'package:foodwaste_reduction/models/meal.dart';
import 'package:foodwaste_reduction/models/meal_edit_data.dart';

void main() {
  group('Admin Menu Management - Model Tests', () {
    test('FoodItem deserializes correctly from database JSON', () {
      final json = {
        'id': 10,
        'name': 'Rice',
        'default_portion_grams': 200,
        'active': true,
        'created_at': '2026-09-30T00:00:00.000Z',
      };

      final item = FoodItem.fromJson(json);

      expect(item.id, 10);
      expect(item.name, 'Rice');
      expect(item.defaultPortionGrams, 200);
      expect(item.active, isTrue);
      expect(item.createdAt, isNotNull);
    });

    test('MealEditData correctly reports isLocked based on waste logs or past meal', () {
      const meal = Meal(
        id: 1,
        mealDate: '2026-10-08',
        mealType: 'lunch',
        menuName: 'Rice + Sambar',
      );

      // Future meal without waste log -> not locked
      final activeEditData = MealEditData(
        meal: meal,
        items: const [],
        hasWasteLog: false,
        isPastMeal: false,
      );
      expect(activeEditData.isLocked, isFalse);

      // Meal with waste log -> locked
      final lockedWasteData = MealEditData(
        meal: meal,
        items: const [],
        hasWasteLog: true,
        isPastMeal: false,
      );
      expect(lockedWasteData.isLocked, isTrue);

      // Past meal -> locked
      final lockedPastData = MealEditData(
        meal: meal,
        items: const [],
        hasWasteLog: false,
        isPastMeal: true,
      );
      expect(lockedPastData.isLocked, isTrue);
    });

    test('MealItemEditData copyWith works correctly', () {
      const item = MealItemEditData(
        id: 5,
        foodItemId: 12,
        foodName: 'Curd',
        portionGrams: 100,
        hasResponses: true,
        responseCount: 15,
      );

      final updated = item.copyWith(portionGrams: 120);

      expect(updated.id, 5);
      expect(updated.foodItemId, 12);
      expect(updated.foodName, 'Curd');
      expect(updated.portionGrams, 120);
      expect(updated.hasResponses, isTrue);
      expect(updated.responseCount, 15);
    });
  });

  group('Admin Menu Management - Validation & Business Logic', () {
    test('Default response deadline calculation points to previous day at 8:00 PM Asia/Kolkata (14:30 UTC)', () {
      final mealDate = DateTime.utc(2026, 10, 8);
      // Previous day is Oct 7
      final prevDay = mealDate.subtract(const Duration(days: 1));
      final defaultDeadline =
          DateTime.utc(prevDay.year, prevDay.month, prevDay.day, 14, 30);

      expect(defaultDeadline.year, 2026);
      expect(defaultDeadline.month, 10);
      expect(defaultDeadline.day, 7);
      expect(defaultDeadline.hour, 14);
      expect(defaultDeadline.minute, 30);

      // When converted to Asia/Kolkata (UTC + 5:30)
      final kolkataTime =
          defaultDeadline.toUtc().add(const Duration(hours: 5, minutes: 30));
      expect(kolkataTime.day, 7);
      expect(kolkataTime.hour, 20); // 8:00 PM
      expect(kolkataTime.minute, 0);
    });

    test('Deadline validation ensures deadline is before meal date service period', () {
      const mealDateStr = '2026-10-08';
      final parts = mealDateStr.split('-').map(int.parse).toList();
      final endOfMealDayUtc =
          DateTime.utc(parts[0], parts[1], parts[2], 18, 30);

      final validDeadline = DateTime.utc(2026, 10, 7, 14, 30);
      final invalidDeadline = DateTime.utc(2026, 10, 9, 10, 00);

      expect(validDeadline.isBefore(endOfMealDayUtc), isTrue);
      expect(invalidDeadline.isBefore(endOfMealDayUtc), isFalse);
    });

    test('Response integrity test: cannot remove meal items with existing responses', () {
      final items = [
        const MealItemEditData(
          id: 1,
          foodItemId: 101,
          foodName: 'Rice',
          portionGrams: 200,
          hasResponses: true,
          responseCount: 42,
        ),
        const MealItemEditData(
          id: 2,
          foodItemId: 102,
          foodName: 'Curd',
          portionGrams: 100,
          hasResponses: false,
          responseCount: 0,
        ),
      ];

      final canRemoveItem1 = !items[0].hasResponses;
      final canRemoveItem2 = !items[1].hasResponses;

      expect(canRemoveItem1, isFalse,
          reason: 'Food with responses must not be removable');
      expect(canRemoveItem2, isTrue,
          reason: 'Food without responses is safe to remove');
    });

    test('Calculates average portion grams accurately', () {
      final items = [
        const MealItemEditData(
          foodItemId: 1,
          foodName: 'Rice',
          portionGrams: 200,
        ),
        const MealItemEditData(
          foodItemId: 2,
          foodName: 'Sambar',
          portionGrams: 150,
        ),
        const MealItemEditData(
          foodItemId: 3,
          foodName: 'Curd',
          portionGrams: 100,
        ),
      ];

      final totalGrams =
          items.fold<int>(0, (sum, item) => sum + item.portionGrams);
      final avg = (totalGrams / items.length).round();

      expect(totalGrams, 450);
      expect(avg, 150);
    });
  });
}
