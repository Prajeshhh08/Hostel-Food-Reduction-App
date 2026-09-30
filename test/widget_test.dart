import 'package:flutter_test/flutter_test.dart';
import 'package:foodwaste_reduction/core/utils/validators.dart';

void main() {
  group('Validators Test', () {
    test('Roll number format validation', () {
      expect(Validators.validateRollNumber('25BCM539'), isNull);
      expect(Validators.validateRollNumber('25BDS214'), isNull);
      expect(Validators.validateRollNumber('25BCT108'), isNull);
      expect(Validators.validateRollNumber('25BIT421'), isNull);

      expect(Validators.validateRollNumber('ABC'), isNotNull);
      expect(Validators.validateRollNumber('12345'), isNotNull);
      expect(Validators.validateRollNumber(''), isNotNull);
    });

    test('Course consistency match validation', () {
      expect(
        Validators.validateCourseMatch(
          rollNumber: '25BCM539',
          selectedCourseCode: 'BCM',
        ),
        isNull,
      );

      expect(
        Validators.validateCourseMatch(
          rollNumber: '25BCM539',
          selectedCourseCode: 'BDS',
        ),
        isNotNull,
      );
    });

    test('Waste portions validation', () {
      expect(
        Validators.validateWastePortions(
          prepared: 100,
          served: 80,
          wasted: 20,
        ),
        isNull,
      );

      expect(
        Validators.validateWastePortions(
          prepared: 100,
          served: 90,
          wasted: 20,
        ),
        isNotNull,
      );
    });
  });
}
