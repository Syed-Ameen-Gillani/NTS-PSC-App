import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'lesson_curriculum_activity_rows.dart';
import 'lesson_curriculum_tile.dart';

class LiveLessonModuleGroup extends StatelessWidget {
  const LiveLessonModuleGroup({
    super.key,
    required this.courseId,
    required this.module,
    required this.moduleNumber,
    required this.currentLesson,
    required this.completedLessonIds,
    required this.onSelectLesson,
    this.isInstructorPreview = false,
  });

  final String courseId;
  final CourseModuleModel module;
  final int moduleNumber;
  final LessonModel currentLesson;
  final Set<String> completedLessonIds;
  final ValueChanged<LessonModel> onSelectLesson;
  final bool isInstructorPreview;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.r),
      side: const BorderSide(color: AppColors.grey300),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 12.h),
          child: Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '$moduleNumber',
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${module.lessons.length} ${module.lessons.length == 1 ? 'lesson' : 'lessons'}',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 10.sp,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.grey300),
        for (var index = 0; index < module.lessons.length; index++) ...[
          _LessonRow(
            lesson: module.lessons[index],
            indexLabel: '$moduleNumber.${index + 1}',
            selected: module.lessons[index].id == currentLesson.id,
            complete: completedLessonIds.contains(module.lessons[index].id),
            onTap: () => onSelectLesson(module.lessons[index]),
          ),
          LessonCurriculumActivityRows(
            scope: CurriculumScope(
              courseId: courseId,
              moduleId: module.id,
              lessonId: module.lessons[index].id,
            ),
            lesson: module.lessons[index],
            isInstructorPreview: isInstructorPreview,
          ),
          if (index != module.lessons.length - 1)
            Padding(
              padding: EdgeInsets.only(left: 52.w),
              child: const Divider(height: 1, color: AppColors.grey200),
            ),
        ],
      ],
    ),
  );
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.indexLabel,
    required this.selected,
    required this.complete,
    required this.onTap,
  });

  final LessonModel lesson;
  final String indexLabel;
  final bool selected;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LessonCurriculumTile(
    title: '$indexLabel ${lesson.title}',
    subtitle: '${lesson.durationMinutes} min',
    selected: selected,
    complete: complete,
    icon: lesson.isLocked
        ? Icons.lock_outline_rounded
        : lesson.videoPath.isEmpty && lesson.videoUrl.isEmpty
        ? Icons.article_outlined
        : selected
        ? Icons.pause_circle_outline_rounded
        : Icons.play_circle_outline_rounded,
    onTap: lesson.isLocked ? null : onTap,
  );
}
