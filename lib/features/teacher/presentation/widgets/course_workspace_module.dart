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
import 'package:nts_psc_app/features/teacher/domain/lesson_limits.dart';

class CourseWorkspaceModule extends ConsumerWidget {
  const CourseWorkspaceModule({
    super.key,
    required this.courseId,
    required this.module,
    required this.index,
    required this.onAddLesson,
  });
  final String courseId;
  final CourseModuleModel module;
  final int index;
  final VoidCallback onAddLesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    color: AppColors.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.r),
      side: const BorderSide(color: AppColors.grey300),
    ),
    clipBehavior: Clip.antiAlias,
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey(module.id),
        initiallyExpanded: index == 0,
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        leading: Container(
          width: 36.w,
          height: 36.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            '${index + 1}'.padLeft(2, '0'),
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 12.sp,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          module.title,
          style: AppTextStyles.interSemiBold16.copyWith(fontSize: 14.sp),
        ),
        subtitle: Text(
          '${module.lessons.length}/$maxLessonsPerModule lessons',
          style: AppTextStyles.interRegular14.copyWith(
            fontSize: 12.sp,
            color: AppColors.grey500,
          ),
        ),
        children: [
          Divider(height: 1.h, color: AppColors.grey200),
          if (module.lessons.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'No lessons added yet.',
                style: AppTextStyles.interRegular14.copyWith(
                  color: AppColors.grey500,
                ),
              ),
            ),
          for (var i = 0; i < module.lessons.length; i++)
            _lesson(context, ref, module.lessons[i], i),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 8.h,
                      ),
                      textStyle: AppTextStyles.interMedium16.copyWith(
                        fontSize: 13.sp,
                      ),
                    ),
                    onPressed: module.lessons.length >= maxLessonsPerModule
                        ? null
                        : onAddLesson,
                    icon: Icon(Icons.add, size: 18.w),
                    label: Text(
                      module.lessons.length >= maxLessonsPerModule
                          ? 'Module full'
                          : 'Add lesson',
                    ),
                  ),
                ),
                if (module.lessons.isNotEmpty && AppConfig.isSupabaseEnabled)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 8.h,
                        ),
                      ),
                      onPressed: () => _openLessonStudio(context),
                      icon: Icon(Icons.folder_outlined, size: 18.w),
                      label: Text(
                        'Materials & assessments',
                        style: AppTextStyles.interMedium16.copyWith(
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _openLessonStudio(BuildContext context) async {
    if (module.lessons.length == 1) {
      await context.pushNamed(
        AppRoute.teacherLessonMedia.name,
        extra: module.lessons.first,
      );
      return;
    }
    final lesson = await showModalBottomSheet<LessonModel>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a lesson',
                style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                'Open its materials and assessments in Lesson Studio.',
                style: AppTextStyles.interRegular14.copyWith(
                  color: AppColors.grey600,
                ),
              ),
              SizedBox(height: 12.h),
              for (var i = 0; i < module.lessons.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    module.lessons[i].videoUrl.isNotEmpty ||
                            module.lessons[i].videoPath.isNotEmpty
                        ? Icons.play_circle_outline
                        : Icons.article_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text('${i + 1}. ${module.lessons[i].title}'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(module.lessons[i]),
                ),
            ],
          ),
        ),
      ),
    );
    if (lesson != null && context.mounted) {
      await context.pushNamed(AppRoute.teacherLessonMedia.name, extra: lesson);
    }
  }

  Widget _lesson(
    BuildContext context,
    WidgetRef ref,
    LessonModel lesson,
    int index,
  ) {
    final scope = CurriculumScope(
      courseId: courseId,
      moduleId: module.id,
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
    final icon = LessonClassification.icon(
      lesson,
      hasExternalAssessment: hasAssessment,
    );
    return ListTile(
      onTap: () =>
          context.pushNamed(AppRoute.teacherLessonMedia.name, extra: lesson),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      leading: Icon(
        icon,
        color: AppColors.primary,
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
              '$classification  |  ${lesson.durationMinutes} min',
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
