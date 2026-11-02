import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_subtopic.dart';
import 'package:nts_psc_app/features/curriculum/presentation/student_resource_navigation.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/learning_outcome_provider.dart';
import 'lesson_curriculum_tile.dart';

final _openingActivity = StateProvider.autoDispose.family<bool, String>(
  (ref, id) => false,
);

class LessonCurriculumActivityRows extends ConsumerWidget {
  const LessonCurriculumActivityRows({
    super.key,
    required this.scope,
    required this.lesson,
    this.isInstructorPreview = false,
  });

  final CurriculumScope scope;
  final LessonModel lesson;
  final bool isInstructorPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = [...lesson.activities]
      ..sort((a, b) => a.order.compareTo(b.order));
    final completedActivityIds = lesson.isLocked || isInstructorPreview
        ? const <String>{}
        : ref
                  .watch(learningOutcomeProvider(lesson.id))
                  .value?['activities']
                  ?.whereType<Map>()
                  .where((item) => item['completed'] == true)
                  .map((item) => item['id'] as String?)
                  .whereType<String>()
                  .toSet() ??
              const <String>{};
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final activity in activities)
          if (LessonSubTopic.fromActivity(activity) case final topic?)
            Consumer(
              builder: (context, ref, _) {
                final key = '${lesson.id}:${activity.id}';
                final busy = ref.watch(_openingActivity(key));
                return LessonCurriculumTile(
                  key: ValueKey('curriculum-activity-${activity.id}'),
                  title: topic.title,
                  subtitle:
                      '${topic.kindLabel} · '
                      '${activity.isRequired ? 'Required' : 'Optional'}',
                  icon: topic.icon,
                  complete: completedActivityIds.contains(activity.id),
                  indent: 24.w,
                  loading: busy,
                  onTap: lesson.isLocked || isInstructorPreview
                      ? null
                      : () async {
                          ref.read(_openingActivity(key).notifier).state = true;
                          try {
                            await openStudentActivity(
                              context,
                              ref,
                              scope,
                              activity,
                            );
                          } finally {
                            if (context.mounted) {
                              ref.read(_openingActivity(key).notifier).state =
                                  false;
                            }
                          }
                        },
                );
              },
            ),
      ],
    );
  }
}
