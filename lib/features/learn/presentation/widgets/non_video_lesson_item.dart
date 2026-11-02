import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_subtopic.dart';
import 'package:nts_psc_app/features/curriculum/presentation/student_resource_navigation.dart';
import '../../domain/lesson_navigation_item.dart';

final _openingItem = StateProvider.autoDispose.family<bool, String>(
  (ref, key) => false,
);

class NonVideoLessonItem extends ConsumerWidget {
  const NonVideoLessonItem({
    super.key,
    required this.courseId,
    required this.item,
    this.isInstructorPreview = false,
  });
  final String courseId;
  final LessonNavigationItem item;
  final bool isInstructorPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = item.activity == null
        ? null
        : LessonSubTopic.fromActivity(item.activity!);
    final kind = topic?.kindLabel ?? 'Lesson content';
    final action = switch (item.activity?.kind) {
      'quiz' => 'Open quiz',
      'assignment' => 'Open assignment',
      'material' => 'Open handout',
      'reading' => 'Read lesson',
      _ => 'Open materials',
    };
    final scope = CurriculumScope(
      courseId: courseId,
      moduleId: item.moduleId,
      lessonId: item.lesson.id,
    );
    final stateKey = '$courseId:${item.key}';
    final busy = ref.watch(_openingItem(stateKey));
    return Container(
      key: const ValueKey('non-video-lesson-item'),
      color: AppColors.settingsCardBackground,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            topic?.icon ?? Icons.menu_book_outlined,
            size: 30.w,
            color: AppColors.primary,
          ),
          SizedBox(height: 10.h),
          Text(
            kind,
            style: AppTextStyles.interSemiBold16.copyWith(
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Select "$action" to continue with this item.',
            textAlign: TextAlign.center,
            style: AppTextStyles.interRegular14.copyWith(
              color: AppColors.grey600,
            ),
          ),
          SizedBox(height: 10.h),
          TextButton(
            onPressed: isInstructorPreview || item.lesson.isLocked || busy
                ? null
                : () async {
                    ref.read(_openingItem(stateKey).notifier).state = true;
                    try {
                      if (item.activity != null) {
                        await openStudentActivity(
                          context,
                          ref,
                          scope,
                          item.activity!,
                        );
                      } else {
                        await context.pushNamed(
                          AppRoute.curriculumResources.name,
                          extra: scope,
                        );
                      }
                    } finally {
                      if (context.mounted) {
                        ref.read(_openingItem(stateKey).notifier).state = false;
                      }
                    }
                  },
            child: Text(busy ? 'Opening…' : action),
          ),
        ],
      ),
    );
  }
}
