import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_classification.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/learn/domain/lesson_player_mode.dart';
import 'package:nts_psc_app/features/learn/domain/learning_access.dart';
import 'package:nts_psc_app/features/teacher/domain/lesson_limits.dart';

class CourseCurriculumTab extends StatelessWidget {
  const CourseCurriculumTab({
    super.key,
    required this.course,
    required this.isTeacher,
    this.isInstructorPreview = false,
    this.onLessonReturned,
  });
  final CourseModel course;
  final bool isTeacher;
  final bool isInstructorPreview;
  final VoidCallback? onLessonReturned;
  Future<void> _open(BuildContext context, LessonModel lesson) async {
    await context.pushNamed(
      AppRoute.lessonPlayer.name,
      extra: {
        'course': course,
        'lesson': lesson,
        'mode': isInstructorPreview
            ? LessonPlayerMode.instructorPreview
            : LessonPlayerMode.learning,
      },
    );
    if (context.mounted) onLessonReturned?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (course.modules.isEmpty) {
      return const Center(child: Text('No modules added yet.'));
    }
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        for (var m = 0; m < course.modules.length; m++)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Material(
              color: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
                side: const BorderSide(color: AppColors.grey300),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: PageStorageKey(
                    'module:${course.id}:${course.modules[m].id}',
                  ),
                  initiallyExpanded: m == 0,
                  tilePadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 6.h,
                  ),
                  leading: Container(
                    width: 36.w,
                    height: 36.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${m + 1}'.padLeft(2, '0'),
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    course.modules[m].title,
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 14.sp,
                    ),
                  ),
                  subtitle: Text(
                    '${course.modules[m].lessons.length}/$maxLessonsPerModule lessons',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                  children: [
                    Divider(height: 1.h, color: AppColors.grey200),
                    if (course.modules[m].lessons.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Text(
                          'No lessons added yet.',
                          style: AppTextStyles.interRegular14.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                      ),
                    for (
                      var l = 0;
                      l < course.modules[m].lessons.length;
                      l++
                    )
                      _LessonOutline(
                        courseId: course.id,
                        moduleId: course.modules[m].id,
                        lesson: course.modules[m].lessons[l],
                        index: l,
                        onOpen: () =>
                            _open(context, course.modules[m].lessons[l]),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LessonOutline extends ConsumerWidget {
  const _LessonOutline({
    required this.courseId,
    required this.moduleId,
    required this.lesson,
    required this.index,
    required this.onOpen,
  });
  final String courseId;
  final String moduleId;
  final LessonModel lesson;
  final int index;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = CurriculumScope(
      courseId: courseId,
      moduleId: moduleId,
      lessonId: lesson.id,
    );
    final summary = AppConfig.isSupabaseEnabled
        ? ref.watch(curriculumAttachmentSummaryProvider(scope)).value
        : null;
    final hasAssessment =
        summary != null && (summary.quizzes > 0 || summary.assignments > 0);
    final classification = LessonClassification.classify(
      lesson,
      hasExternalAssessment: hasAssessment,
    );
    final classificationIcon = LessonClassification.icon(
      lesson,
      hasExternalAssessment: hasAssessment,
    );
    final available =
        !lesson.isLocked &&
        (lesson.activities.isNotEmpty ||
            lesson.notes.isNotEmpty ||
            lesson.videoPath.isNotEmpty ||
            lesson.videoUrl.isNotEmpty ||
            (summary != null && !summary.isEmpty));

    final IconData leadingIcon;
    final Color iconColor;
    if (lesson.isCompleted) {
      leadingIcon = Icons.check_circle_outline;
      iconColor = AppColors.success;
    } else if (lesson.isLocked) {
      leadingIcon = Icons.lock_outline;
      iconColor = AppColors.primary;
    } else {
      leadingIcon = classificationIcon;
      iconColor = AppColors.primary;
    }

    final String subtitleText;
    if (lesson.isLocked) {
      subtitleText = LearningAccess.message(lesson.accessState);
    } else if (!available) {
      subtitleText = 'No learning activities';
    } else {
      subtitleText = '$classification  |  ${lesson.durationMinutes} min';
    }

    return ListTile(
      key: ValueKey('open-lesson:${lesson.id}'),
      onTap: available ? onOpen : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      leading: Icon(
        leadingIcon,
        color: iconColor,
        size: 24.w,
      ),
      title: Text(
        '${index + 1}. ${lesson.title}',
        style: AppTextStyles.interMedium16.copyWith(
          fontSize: 14.sp,
          color: AppColors.onBackground,
        ),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 6.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitleText,
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 11.sp,
                color: AppColors.grey500,
              ),
            ),
            if (summary != null && !summary.isEmpty) ...[
              SizedBox(height: 3.h),
              Text(
                summary.label,
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
