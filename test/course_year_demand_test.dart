import 'package:flutter_test/flutter_test.dart';
import 'package:foodwaste_reduction/models/course_year_demand.dart';
import 'package:foodwaste_reduction/providers/dashboard_provider.dart';

void main() {
  group('CourseYearDemand Model Tests', () {
    test('Correctly deserializes filtered demand JSON from RPC', () {
      final json = {
        'food_item_id': 1,
        'food_name': 'Rice',
        'course_id': 10,
        'course_code': 'BCM',
        'course_name': 'Computer Science',
        'study_year_id': 2,
        'study_year_label': '2nd Year',
        'wants_count': 27,
        'doesnt_want_count': 5,
      };

      final demand = CourseYearDemand.fromJson(json);

      expect(demand.foodItemId, 1);
      expect(demand.foodName, 'Rice');
      expect(demand.courseId, 10);
      expect(demand.courseCode, 'BCM');
      expect(demand.courseName, 'Computer Science');
      expect(demand.studyYearId, 2);
      expect(demand.studyYearLabel, '2nd Year');
      expect(demand.wantsCount, 27);
      expect(demand.doesntWantCount, 5);
      expect(demand.totalResponses, 32);
    });

    test('Handles null course and study year gracefully (e.g. course/year = all)', () {
      final json = {
        'food_item_id': 2,
        'food_name': 'Sambar',
        'course_id': null,
        'course_code': null,
        'course_name': null,
        'study_year_id': null,
        'study_year_label': null,
        'wants_count': 96,
        'doesnt_want_count': 24,
      };

      final demand = CourseYearDemand.fromJson(json);

      expect(demand.foodItemId, 2);
      expect(demand.foodName, 'Sambar');
      expect(demand.courseId, isNull);
      expect(demand.studyYearId, isNull);
      expect(demand.wantsCount, 96);
      expect(demand.doesntWantCount, 24);
      expect(demand.totalResponses, 120);
    });
  });

  group('CourseYearDemandFilter Tests', () {
    test('Filter equality and hash code check', () {
      const filter1 = CourseYearDemandFilter(
        mealId: 1,
        courseId: 10,
        studyYearId: 2,
      );
      const filter2 = CourseYearDemandFilter(
        mealId: 1,
        courseId: 10,
        studyYearId: 2,
      );
      const filter3 = CourseYearDemandFilter(
        mealId: 1,
        courseId: 10,
        studyYearId: 3,
      );

      expect(filter1, equals(filter2));
      expect(filter1.hashCode, equals(filter2.hashCode));
      expect(filter1, isNot(equals(filter3)));
    });
  });
}
