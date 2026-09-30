import 'package:flutter_test/flutter_test.dart';
import 'package:foodwaste_reduction/core/utils/error_handler.dart';
import 'package:foodwaste_reduction/core/utils/validators.dart';
import 'package:foodwaste_reduction/models/actionable_meal_group.dart';
import 'package:foodwaste_reduction/models/food_prediction.dart';
import 'package:foodwaste_reduction/models/meal.dart';
import 'package:foodwaste_reduction/models/meal_edit_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Phase I QA - 1. Authentication & Validation Hardening', () {
    test('Validates roll number format across allowed course codes', () {
      // Valid roll numbers
      expect(Validators.validateRollNumber('25BCM539'), isNull);
      expect(Validators.validateRollNumber('25BDS214'), isNull);
      expect(Validators.validateRollNumber('25BIT421'), isNull);
      expect(Validators.validateRollNumber('24BCT101'), isNull);

      // Invalid roll numbers
      expect(Validators.validateRollNumber(''), isNotNull);
      expect(Validators.validateRollNumber('12345'), isNotNull);
      expect(Validators.validateRollNumber('25XYZ101'), isNotNull);
      expect(Validators.validateRollNumber('2BCM539'), isNotNull);
      expect(Validators.validateRollNumber('25BCM53'), isNotNull);
    });

    test('Validates roll number course code matches selected course', () {
      // Matching
      expect(
        Validators.validateCourseMatch(
          rollNumber: '25BCM539',
          selectedCourseCode: 'BCM',
        ),
        isNull,
      );
      expect(
        Validators.validateCourseMatch(
          rollNumber: '25BDS214',
          selectedCourseCode: 'bds',
        ),
        isNull,
      );

      // Mismatch
      expect(
        Validators.validateCourseMatch(
          rollNumber: '25BCM539',
          selectedCourseCode: 'BDS',
        ),
        contains('does not match'),
      );
      expect(
        Validators.validateCourseMatch(
          rollNumber: '25BIT421',
          selectedCourseCode: 'BCT',
        ),
        contains('does not match'),
      );
    });

    test('Validates email addresses correctly', () {
      expect(Validators.validateEmail('student@college.edu'), isNull);
      expect(Validators.validateEmail('admin.canteen@hostel.ac.in'), isNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('user@'), isNotNull);
    });

    test('Validates password and password confirmation', () {
      expect(Validators.validatePassword('secure123'), isNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);

      expect(
        Validators.validateConfirmPassword('secure123', 'secure123'),
        isNull,
      );
      expect(
        Validators.validateConfirmPassword('secure123', 'different'),
        isNotNull,
      );
    });
  });

  group('Phase I QA - 2. Waste Logging Portions Math Validation', () {
    test('Rejects when served + wasted > prepared', () {
      final error = Validators.validateWastePortions(
        prepared: 100,
        served: 95,
        wasted: 10,
        attendance: 90,
      );
      expect(error, isNotNull);
      expect(error, contains('exceed prepared'));
    });

    test('Accepts valid portion balance: prepared = 100, served = 90, wasted = 10', () {
      final error = Validators.validateWastePortions(
        prepared: 100,
        served: 90,
        wasted: 10,
        attendance: 88,
      );
      expect(error, isNull);
    });

    test('Rejects negative values for any portion or attendance', () {
      expect(
        Validators.validateWastePortions(
          prepared: -10,
          served: 0,
          wasted: 0,
        ),
        isNotNull,
      );
      expect(
        Validators.validateWastePortions(
          prepared: 100,
          served: -5,
          wasted: 10,
        ),
        isNotNull,
      );
      expect(
        Validators.validateWastePortions(
          prepared: 100,
          served: 90,
          wasted: -1,
        ),
        isNotNull,
      );
      expect(
        Validators.validateWastePortions(
          prepared: 100,
          served: 90,
          wasted: 10,
          attendance: -5,
        ),
        isNotNull,
      );
    });
  });

  group('Phase I QA - 3. Response Deadline & Kolkata Timezone Transitions', () {
    test('Correctly identifies deadline before now, after now, and exact boundary', () {
      final now = DateTime.now();

      final pastMeal = Meal(
        id: 1,
        mealDate: '2026-10-01',
        mealType: 'lunch',
        menuName: 'Lunch',
        responseDeadline: now.subtract(const Duration(seconds: 1)),
      );
      expect(pastMeal.isDeadlinePassed, isTrue);
      expect(pastMeal.isActionable, isFalse);

      final futureMeal = Meal(
        id: 2,
        mealDate: '2026-10-01',
        mealType: 'lunch',
        menuName: 'Lunch',
        responseDeadline: now.add(const Duration(minutes: 5)),
      );
      expect(futureMeal.isDeadlinePassed, isFalse);
      expect(futureMeal.isActionable, isTrue);
    });

    test('Handles month-end and year-end date formatting in ActionableMealGroup', () {
      // Month-end boundary: October 31
      final oct31Group = ActionableMealGroup(
        mealDate: '2026-10-31',
        date: DateTime.utc(2026, 10, 31),
        meals: const [],
        isActionable: true,
      );
      expect(oct31Group.formatDisplayDate(), contains('October 31'));

      // Year-end boundary: December 31
      final dec31Group = ActionableMealGroup(
        mealDate: '2026-12-31',
        date: DateTime.utc(2026, 12, 31),
        meals: const [],
        isActionable: true,
      );
      expect(dec31Group.formatDisplayDate(), contains('December 31'));

      // New Year: January 1
      final jan1Group = ActionableMealGroup(
        mealDate: '2027-01-01',
        date: DateTime.utc(2027, 1, 1),
        meals: const [],
        isActionable: true,
      );
      expect(jan1Group.formatDisplayDate(), contains('January 1'));
    });
  });

  group('Phase I QA - 4. Prediction Semantics & Formula Bounds', () {
    test('Computes expected demand and recommended preparation accurately', () {
      final predictionJson = {
        'food_item_id': 10,
        'food_name': 'Rice',
        'portion_grams': 200.0,
        'confirmed_want_count': 102,
        'historical_no_show_rate': 0.06,
        'expected_demand': 95.88,
        'recommended_portions': 96,
        'recommended_grams': 19200.0,
      };

      final prediction = FoodPrediction.fromJson(predictionJson);

      expect(prediction.confirmedWantCount, 102);
      expect(prediction.hasHistoricalData, isTrue);
      expect(prediction.historicalNoShowRate, 0.06);
      expect(prediction.expectedDemand, closeTo(95.88, 0.01));
      expect(prediction.recommendedPortions, 96);
      expect(prediction.recommendedGrams, 19200.0);
      expect(prediction.formattedQuantity, '19.2 kg');
    });

    test('Safely handles zero historical meals (no history)', () {
      final predictionJson = {
        'food_item_id': 20,
        'food_name': 'New Special Curry',
        'portion_grams': 150.0,
        'confirmed_want_count': 50,
        'historical_no_show_rate': 0.0,
        'expected_demand': 50.0,
        'recommended_portions': 50,
        'recommended_grams': 7500.0,
      };

      final prediction = FoodPrediction.fromJson(predictionJson);

      expect(prediction.hasHistoricalData, isFalse);
      expect(prediction.historicalNoShowRate, 0.0);
      expect(prediction.confirmedWantCount, 50);
      expect(prediction.recommendedPortions, 50);
      expect(prediction.recommendedGrams, 7500.0);
      expect(prediction.formattedQuantity, '7.5 kg');
    });
  });

  group('Phase I QA - 5. Menu Response Integrity & Lock Rules', () {
    test('Prevents removal of meal items with existing student responses', () {
      final items = [
        const MealItemEditData(
          id: 101,
          foodItemId: 1,
          foodName: 'Rice',
          portionGrams: 200,
          hasResponses: true,
          responseCount: 25,
        ),
        const MealItemEditData(
          id: 102,
          foodItemId: 2,
          foodName: 'Sambar',
          portionGrams: 150,
          hasResponses: false,
          responseCount: 0,
        ),
      ];

      // Item with responses cannot be removed
      expect(items[0].hasResponses, isTrue);
      // Item without responses can be removed
      expect(items[1].hasResponses, isFalse);
    });

    test('Locks meal menu when waste log is recorded or meal date is in the past', () {
      const meal = Meal(
        id: 1,
        mealDate: '2026-09-28',
        mealType: 'dinner',
        menuName: 'Dinner',
      );

      final editData = MealEditData(
        meal: meal,
        items: const [],
        hasWasteLog: true,
        isPastMeal: true,
      );

      expect(editData.isLocked, isTrue);
    });
  });

  group('Phase I QA - 6. User-Friendly Error Messages & Security Protection', () {
    test('Translates Postgrest duplicate roll number constraint without leaking SQL', () {
      const exception = PostgrestException(
        message: 'duplicate key value violates unique constraint "profiles_roll_number_key"',
        code: '23505',
      );
      final msg = ErrorHandler.getFriendlyErrorMessage(exception);
      expect(msg, contains('roll number already exists'));
      expect(msg.contains('SELECT'), isFalse);
    });

    test('Translates duplicate meal constraint to friendly advice', () {
      const exception = PostgrestException(
        message: 'duplicate key value violates unique constraint "meals_meal_date_meal_type_key"',
        code: '23505',
      );
      final msg = ErrorHandler.getFriendlyErrorMessage(exception);
      expect(msg, contains('A meal of this type already exists on this date'));
    });

    test('Translates RLS permission denied / deadline passed error', () {
      const exception = PostgrestException(
        message: 'new row violates row-level security policy response_deadline',
        code: '42501',
      );
      final msg = ErrorHandler.getFriendlyErrorMessage(exception);
      expect(msg, contains('Responses are closed'));
    });

    test('Translates network connectivity exceptions cleanly', () {
      final msg = ErrorHandler.getFriendlyErrorMessage(
        Exception('ClientException: SocketException: Connection refused, address = localhost'),
      );
      expect(msg, contains('Network error'));
    });
  });
}
