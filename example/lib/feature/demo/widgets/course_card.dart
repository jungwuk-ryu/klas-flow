import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

/// 과목 목록과 현재 과목 선택 UI를 담당한다.
class CourseCard extends StatelessWidget {
  final List<KlasCourse> courses;
  final KlasCourse? currentCourse;
  final bool isLoading;
  final String Function(KlasCourse course) courseLabel;
  final Future<void> Function(KlasCourse? course) onCourseChanged;

  const CourseCard({
    super.key,
    required this.courses,
    required this.currentCourse,
    required this.isLoading,
    required this.courseLabel,
    required this.onCourseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Courses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Available courses: ${courses.length}'),
            const SizedBox(height: 8),
            if (courses.isEmpty)
              const Text('No course context available.')
            else
              DropdownButtonFormField<KlasCourse>(
                initialValue: currentCourse,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Current course',
                ),
                items: courses
                    .map(
                      (course) => DropdownMenuItem<KlasCourse>(
                        value: course,
                        child: Text(
                          courseLabel(course),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: isLoading ? null : onCourseChanged,
              ),
          ],
        ),
      ),
    );
  }
}
