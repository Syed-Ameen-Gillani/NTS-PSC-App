import 'automatic_learning_status.dart';
import 'lesson_meta_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'course_scoped_resources_link.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/course_download_button.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/lesson_action_button.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/live_lesson_module_group.dart';

class LiveLessonContent extends StatelessWidget {
  const LiveLessonContent({
    super.key,
    required this.course,
    required this.lesson,
    required this.lessons,
    required this.completedLessonIds,
    required this.currentIndex,
    required this.savingProgress,
    required this.autoplay,
    required this.onSelectLesson,
    required this.onMarkComplete,
    required this.onAutoplayChanged,
    this.isInstructorPreview = false,
    this.itemNavigation,
    this.contentTitle,
  });

  final CourseModel course;
  final LessonModel lesson;
  final List<LessonModel> lessons;
  final Set<String> completedLessonIds;
  final int currentIndex;
  final bool savingProgress;
  final bool autoplay;
  final ValueChanged<LessonModel> onSelectLesson;
  final VoidCallback onMarkComplete;
  final ValueChanged<bool> onAutoplayChanged;
  final bool isInstructorPreview;
  final ({int index, int count, VoidCallback? previous, VoidCallback? next})?
  itemNavigation;
  final String? contentTitle;
  bool get _isComplete => completedLessonIds.contains(lesson.id);
  bool get _hasPrevious =>
      currentIndex > 0 && !lessons[currentIndex - 1].isLocked;
  bool get _hasNext =>
      currentIndex >= 0 &&
      currentIndex + 1 < lessons.length &&
      !lessons[currentIndex + 1].isLocked;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LessonMetaRow(
              course: course,
              lesson: lesson,
              lessonNumber: (itemNavigation?.index ?? currentIndex) + 1,
              lessonCount: itemNavigation?.count ?? lessons.length,
              hasPrevious: itemNavigation == null
                  ? _hasPrevious
                  : itemNavigation!.previous != null,
              hasNext: itemNavigation == null
                  ? _hasNext
                  : itemNavigation!.next != null,
              onPrevious: itemNavigation == null
                  ? () => onSelectLesson(lessons[currentIndex - 1])
                  : () => itemNavigation!.previous?.call(),
              onNext: itemNavigation == null
                  ? () => onSelectLesson(lessons[currentIndex + 1])
                  : () => itemNavigation!.next?.call(),
              isItemNavigation: itemNavigation != null,
            ),
            SizedBox(height: 16.h),
            Text(
              contentTitle?.isNotEmpty == true ? contentTitle! : lesson.title,
              style: AppTextStyles.interBold24.copyWith(
                fontSize: 20.sp,
                color: AppColors.onBackground,
                height: 1.25,
              ),
            ),
            if (course.author.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                'Instructor: ${course.author}',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ],
        ),
      ),
      AutomaticLearningStatus(
        lessonId: lesson.id,
        previewRequiredCount: isInstructorPreview
            ? lesson.activities.where((item) => item.isRequired).length
            : null,
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 18.h),
            _LessonActionBar(
              course: course,
              lesson: lesson,
              complete: _isComplete,
              saving: savingProgress,
              locked: lesson.isLocked,
              onComplete: onMarkComplete,
              isInstructorPreview: isInstructorPreview,
            ),
            if (lessons.length > 1) ...[
              SizedBox(height: 8.h),
              IgnorePointer(
                ignoring: isInstructorPreview,
                child: _AutoplayRow(
                  value: autoplay,
                  onChanged: onAutoplayChanged,
                ),
              ),
            ],
            if (lesson.notes.trim().isNotEmpty)
              IgnorePointer(
                ignoring: isInstructorPreview,
                child: TextButton.icon(
                  onPressed: lesson.isLocked
                      ? null
                      : () => context.pushNamed(
                          AppRoute.lessonReading.name,
                          queryParameters: {'lessonId': lesson.id},
                        ),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Read lesson'),
                ),
              ),
            if (lesson.notes.trim().isNotEmpty) ...[
              SizedBox(height: 24.h),
              Text(
                'About this lesson',
                style: AppTextStyles.interSemiBold16.copyWith(
                  fontSize: 15.sp,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                lesson.notes,
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.grey600,
                  height: 1.5,
                ),
              ),
            ],
            SizedBox(height: 28.h),
          ],
        ),
      ),
      _CurriculumSection(
        course: course,
        currentLesson: lesson,
        completedLessonIds: completedLessonIds,
        onSelectLesson: onSelectLesson,
        isInstructorPreview: isInstructorPreview,
      ),
      IgnorePointer(
        ignoring: isInstructorPreview,
        child: CourseScopedResourcesLink(courseId: course.id),
      ),
    ],
  );
}

class _LessonActionBar extends StatelessWidget {
  const _LessonActionBar({
    required this.course,
    required this.lesson,
    required this.complete,
    required this.saving,
    required this.locked,
    required this.onComplete,
    required this.isInstructorPreview,
  });

  final CourseModel course;
  final LessonModel lesson;
  final bool complete;
  final bool saving;
  final bool locked;
  final VoidCallback onComplete;
  final bool isInstructorPreview;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border.symmetric(
        horizontal: BorderSide(color: AppColors.grey300),
      ),
    ),
    child: IgnorePointer(
      ignoring: isInstructorPreview,
      child: Row(
        children: [
          Expanded(
            child: LessonActionButton(
              icon: const Icon(Icons.folder_open_outlined),
              label: 'Materials',
              onTap: lesson.isLocked
                  ? null
                  : () => context.pushNamed(
                      AppRoute.curriculumResources.name,
                      extra: CurriculumScope(
                        courseId: course.id,
                        lessonId: lesson.id,
                      ),
                    ),
              color: AppColors.primary,
            ),
          ),
          SizedBox(
            height: 36.h,
            child: const VerticalDivider(width: 1, color: AppColors.grey300),
          ),
          Expanded(child: CourseDownloadButton(course: course, compact: true)),
          SizedBox(
            height: 36.h,
            child: const VerticalDivider(width: 1, color: AppColors.grey300),
          ),
          Expanded(
            child: isInstructorPreview
                ? LessonActionButton(
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: complete ? 'Completed' : 'Complete',
                    onTap: null,
                    disabledColor: complete
                        ? AppColors.success
                        : AppColors.grey400,
                  )
                : _CompletionStatusAction(
                    lessonId: lesson.id,
                    completed: complete,
                  ),
          ),
        ],
      ),
    ),
  );
}

class _CompletionStatusAction extends ConsumerWidget {
  const _CompletionStatusAction({
    required this.lessonId,
    required this.completed,
  });

  final String lessonId;
  final bool completed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcome = ref.watch(learningOutcomeProvider(lessonId));
    final isComplete = completed || outcome.value?['completed'] == true;
    return LessonActionButton(
      key: const ValueKey('lesson-completion-status'),
      icon: const Icon(Icons.check_circle_outline_rounded),
      label: isComplete ? 'Completed' : 'Complete',
      onTap: null,
      disabledColor: isComplete ? AppColors.success : AppColors.grey400,
    );
  }
}

class _AutoplayRow extends StatelessWidget {
  const _AutoplayRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.grey300)),
    ),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        'Autoplay',
        style: AppTextStyles.interMedium16.copyWith(
          fontSize: 13.sp,
          color: AppColors.onBackground,
        ),
      ),
      subtitle: Text(
        'Play the next lesson automatically',
        style: AppTextStyles.interRegular14.copyWith(
          fontSize: 11.sp,
          color: AppColors.grey500,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.grey300,
        ),
      ),
      onTap: () => onChanged(!value),
    ),
  );
}

class _CurriculumSection extends StatelessWidget {
  const _CurriculumSection({
    required this.course,
    required this.currentLesson,
    required this.completedLessonIds,
    required this.onSelectLesson,
    required this.isInstructorPreview,
  });
  final CourseModel course;
  final LessonModel currentLesson;
  final Set<String> completedLessonIds;
  final ValueChanged<LessonModel> onSelectLesson;
  final bool isInstructorPreview;
  @override
  Widget build(BuildContext context) {
    final moduleIndex = course.modules.indexWhere(
      (module) => module.lessons.any((lesson) => lesson.id == currentLesson.id),
    );
    if (moduleIndex < 0) return const SizedBox.shrink();
    final module = course.modules[moduleIndex];
    return Container(
      width: double.infinity,
      color: AppColors.grey100,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Course curriculum',
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 17.sp,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              Text(
                'Module ${moduleIndex + 1} · ${module.lessons.length} lessons',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          LiveLessonModuleGroup(
            courseId: course.id,
            module: module,
            moduleNumber: moduleIndex + 1,
            currentLesson: currentLesson,
            completedLessonIds: completedLessonIds,
            onSelectLesson: onSelectLesson,
            isInstructorPreview: isInstructorPreview,
          ),
        ],
      ),
    );
  }
}
