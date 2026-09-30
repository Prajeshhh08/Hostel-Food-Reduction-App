import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../models/study_year.dart';

class CourseYearFilterWidget extends StatelessWidget {
  final AsyncValue<List<Course>> coursesAsync;
  final AsyncValue<List<StudyYear>> studyYearsAsync;
  final int? selectedCourseId;
  final int? selectedStudyYearId;
  final ValueChanged<int?> onCourseChanged;
  final ValueChanged<int?> onStudyYearChanged;

  const CourseYearFilterWidget({
    super.key,
    required this.coursesAsync,
    required this.studyYearsAsync,
    required this.selectedCourseId,
    required this.selectedStudyYearId,
    required this.onCourseChanged,
    required this.onStudyYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: Color(0xFF0F172A),
                ),
                SizedBox(width: 6),
                Text(
                  'Filter by Department & Year',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 450;

                final courseDropdown = coursesAsync.when(
                  data: (courses) => DropdownButtonFormField<int?>(
                    initialValue: selectedCourseId,
                    decoration: const InputDecoration(
                      labelText: 'Course',
                      prefixIcon: Icon(Icons.school_outlined, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Courses'),
                      ),
                      ...courses.map((Course c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(
                              '${c.code} (${c.name})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: onCourseChanged,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    'Error loading courses',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                );

                final yearDropdown = studyYearsAsync.when(
                  data: (years) => DropdownButtonFormField<int?>(
                    initialValue: selectedStudyYearId,
                    decoration: const InputDecoration(
                      labelText: 'Year of Study',
                      prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Years'),
                      ),
                      ...years.map((StudyYear y) => DropdownMenuItem<int?>(
                            value: y.id,
                            child: Text(y.label),
                          )),
                    ],
                    onChanged: onStudyYearChanged,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    'Error loading years',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: courseDropdown),
                      const SizedBox(width: 12),
                      Expanded(child: yearDropdown),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      courseDropdown,
                      const SizedBox(height: 12),
                      yearDropdown,
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
