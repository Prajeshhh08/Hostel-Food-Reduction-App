import 'package:flutter_test/flutter_test.dart';
import 'package:foodwaste_reduction/models/actionable_meal_group.dart';
import 'package:foodwaste_reduction/models/meal.dart';
import 'package:foodwaste_reduction/services/meal_service.dart';

void main() {
  group('Advance Meal Planning - Meal Model Tests', () {
    test('isDeadlinePassed returns true when deadline is in the past', () {
      final pastDeadline = DateTime.now().subtract(const Duration(hours: 2));
      final meal = Meal(
        id: 1,
        mealDate: '2026-10-01',
        mealType: 'lunch',
        menuName: 'Standard Lunch',
        responseDeadline: pastDeadline,
      );

      expect(meal.isDeadlinePassed, isTrue);
      expect(meal.isActionable, isFalse);
    });

    test('isDeadlinePassed returns false when deadline is in the future', () {
      final futureDeadline = DateTime.now().add(const Duration(hours: 12));
      final meal = Meal(
        id: 2,
        mealDate: '2026-10-01',
        mealType: 'dinner',
        menuName: 'Standard Dinner',
        responseDeadline: futureDeadline,
      );

      expect(meal.isDeadlinePassed, isFalse);
      expect(meal.isActionable, isTrue);
    });

    test('isDeadlinePassed returns false when responseDeadline is null', () {
      const meal = Meal(
        id: 3,
        mealDate: '2026-10-01',
        mealType: 'breakfast',
        menuName: 'Breakfast',
        responseDeadline: null,
      );

      expect(meal.isDeadlinePassed, isFalse);
      expect(meal.isActionable, isTrue);
    });

    test('formatDeadlineKolkata formats correctly in Asia/Kolkata timezone', () {
      // 2026-09-30 14:30:00 UTC is 2026-09-30 20:00:00 in Asia/Kolkata (UTC+5:30)
      final deadlineUtc = DateTime.utc(2026, 9, 30, 14, 30);
      final meal = Meal(
        id: 4,
        mealDate: '2026-10-01',
        mealType: 'dinner',
        menuName: 'Dinner',
        responseDeadline: deadlineUtc,
      );

      final formatted = meal.formatDeadlineKolkata();
      // Should format time with PM/AM correctly (e.g. "8:00 PM")
      expect(formatted.contains('8:00 PM'), isTrue);
    });
  });

  group('Advance Meal Planning - ActionableMealGroup Grouping Logic', () {
    test('groupMealsByDate correctly groups meals by date and marks the earliest actionable day', () {
      final now = DateTime.now();
      final futureDeadline = now.add(const Duration(hours: 10));
      final pastDeadline = now.subtract(const Duration(hours: 5));

      final meals = [
        // Day 1 (Oct 1) - all meals closed
        Meal(
          id: 1,
          mealDate: '2026-10-01',
          mealType: 'breakfast',
          menuName: 'Breakfast Day 1',
          responseDeadline: pastDeadline,
        ),
        Meal(
          id: 2,
          mealDate: '2026-10-01',
          mealType: 'lunch',
          menuName: 'Lunch Day 1',
          responseDeadline: pastDeadline,
        ),
        // Day 2 (Oct 2) - actionable (deadline in future)
        Meal(
          id: 3,
          mealDate: '2026-10-02',
          mealType: 'breakfast',
          menuName: 'Breakfast Day 2',
          responseDeadline: futureDeadline,
        ),
        Meal(
          id: 4,
          mealDate: '2026-10-02',
          mealType: 'lunch',
          menuName: 'Lunch Day 2',
          responseDeadline: futureDeadline,
        ),
        // Day 3 (Oct 3) - future actionable day
        Meal(
          id: 5,
          mealDate: '2026-10-03',
          mealType: 'lunch',
          menuName: 'Lunch Day 3',
          responseDeadline: futureDeadline.add(const Duration(days: 1)),
        ),
      ];

      final groups = MealService.groupMealsByDate(meals);

      expect(groups.length, 3);

      // Group 1 (Oct 1) is closed, not next actionable
      expect(groups[0].mealDate, '2026-10-01');
      expect(groups[0].isActionable, isFalse);
      expect(groups[0].isNextActionable, isFalse);
      expect(groups[0].meals.length, 2);

      // Group 2 (Oct 2) has open deadline, so it is the next actionable target
      expect(groups[1].mealDate, '2026-10-02');
      expect(groups[1].isActionable, isTrue);
      expect(groups[1].isNextActionable, isTrue);
      expect(groups[1].meals.length, 2);

      // Group 3 (Oct 3) is actionable but not the next one
      expect(groups[2].mealDate, '2026-10-03');
      expect(groups[2].isActionable, isTrue);
      expect(groups[2].isNextActionable, isFalse);
    });

    test('groupMealsByDate returns empty list when meals list is empty', () {
      final groups = MealService.groupMealsByDate([]);
      expect(groups, isEmpty);
    });

    test('ActionableMealGroup formatDisplayDate formats date correctly', () {
      final group = ActionableMealGroup(
        mealDate: '2026-10-01',
        date: DateTime.utc(2026, 10, 1),
        meals: [],
        isActionable: true,
      );

      final display = group.formatDisplayDate();
      expect(display.contains('October 1'), isTrue);
    });
  });
}
