part of 'curriculum_resources_screen.dart';

extension _OwnerResourceHelpers on _Content {
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          message: error is ArgumentError
              ? error.message.toString()
              : 'Could not complete this action. Please retry.',
        );
      }
    }
  }

  Future<void> _openLessonStudio(BuildContext context, WidgetRef ref) async {
    if (details.scope.lessonId != null) {
      LessonModel? lesson;
      if (details.scope.courseId != null) {
        final course = ref
            .read(curriculumCourseProvider(details.scope.courseId!))
            .value;
        if (course != null) {
          for (final m in course.modules) {
            for (final l in m.lessons) {
              if (l.id == details.scope.lessonId) {
                lesson = l;
                break;
              }
            }
          }
        }
      }
      lesson ??= LessonModel(
        id: details.scope.lessonId!,
        title: details.title,
        durationMinutes: 0,
      );
      if (context.mounted) {
        await context.pushNamed(
          AppRoute.teacherLessonMedia.name,
          extra: lesson,
        );
        if (context.mounted) {
          ref.invalidate(curriculumMaterialsProvider(details.scope));
          ref.invalidate(curriculumAssessmentsProvider(details.scope));
          if (details.scope.lessonId != null) {
            ref.invalidate(teacherLessonMediaProvider(details.scope.lessonId!));
          }
        }
      }
      return;
    }

    if (details.scope.courseId != null) {
      final course = await ref.read(
        curriculumCourseProvider(details.scope.courseId!).future,
      );
      if (course != null) {
        final modules = details.scope.moduleId != null
            ? course.modules
                  .where((m) => m.id == details.scope.moduleId)
                  .toList()
            : course.modules;
        final allLessons = modules.expand((m) => m.lessons).toList();
        if (allLessons.isNotEmpty) {
          if (allLessons.length == 1) {
            if (context.mounted) {
              await context.pushNamed(
                AppRoute.teacherLessonMedia.name,
                extra: allLessons.first,
              );
              if (context.mounted) {
                ref.invalidate(curriculumMaterialsProvider(details.scope));
                ref.invalidate(curriculumAssessmentsProvider(details.scope));
              }
            }
            return;
          }
          if (context.mounted) {
            final picked = await showModalBottomSheet<LessonModel>(
              context: context,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              builder: (ctx) => SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 8.h,
                        ),
                        child: Text(
                          'Select Lesson Studio',
                          style: AppTextStyles.interBold24.copyWith(
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      const Divider(),
                      ...allLessons.map(
                        (lesson) => ListTile(
                          leading: const Icon(
                            Icons.layers_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            lesson.title,
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 14.sp,
                            ),
                          ),
                          subtitle: Text(
                            '${lesson.durationMinutes} min',
                            style: AppTextStyles.interRegular14.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.grey400,
                          ),
                          onTap: () => Navigator.of(ctx).pop(lesson),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            if (picked != null && context.mounted) {
              await context.pushNamed(
                AppRoute.teacherLessonMedia.name,
                extra: picked,
              );
              if (context.mounted) {
                ref.invalidate(curriculumMaterialsProvider(details.scope));
                ref.invalidate(curriculumAssessmentsProvider(details.scope));
              }
            }
          }
          return;
        }
      }
    }

    if (context.mounted) {
      CustomToast.showError(
        context,
        message: 'No lessons available to open in Lesson Studio yet.',
      );
    }
  }

  Future<void> _openAssessment(
    BuildContext context,
    WidgetRef ref,
    CurriculumAssessment item,
  ) => _run(context, () async {
    if (item.kind == 'assignment') {
      await context.pushNamed(
        details.canManage
            ? AppRoute.teacherReviewAssignment.name
            : AppRoute.studentAssignment.name,
        queryParameters: {'assignmentId': item.assessmentId},
      );
    } else if (!details.canManage) {
      await context.pushNamed(
        AppRoute.activeQuiz.name,
        queryParameters: {'quizId': item.assessmentId},
      );
    } else {
      final quiz = await ref.read(
        curriculumQuizProvider(item.assessmentId).future,
      );
      if (quiz == null || !context.mounted) return;
      if (!quiz.isPublished) {
        await context.pushNamed(AppRoute.teacherCreateQuiz.name, extra: quiz);
      } else {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.7,
              child: ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  Text(quiz.title, style: Theme.of(ctx).textTheme.titleLarge),
                  for (final question in quiz.questions)
                    ListTile(title: Text(question.questionText)),
                ],
              ),
            ),
          ),
        );
      }
      ref.invalidate(curriculumAssessmentsProvider(details.scope));
    }
  });

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    int? count,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 16.w, color: AppColors.grey600),
          SizedBox(width: 6.w),
          Text(
            title,
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 12.sp,
              color: AppColors.grey600,
              letterSpacing: 0.8,
            ),
          ),
          if (count != null) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 10.sp,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachedVideoCard(
    BuildContext context,
    WidgetRef ref,
    LessonMedia video,
  ) {
    final mbSize = (video.byteSize / (1024 * 1024)).toStringAsFixed(1);
    final isPublished = video.status == 'ready';

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Bar
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isPublished
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPublished
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706),
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        isPublished ? 'Published Video' : 'Attached Video',
                        style: AppTextStyles.interBold24.copyWith(
                          fontSize: 10.sp,
                          letterSpacing: 0.2,
                          color: isPublished
                              ? const Color(0xFF166534)
                              : const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
                if (details.canManage)
                  InkWell(
                    onTap: () => _openLessonStudio(context, ref),
                    borderRadius: BorderRadius.circular(6.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 14.w,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Edit in Studio',
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Video Framed Preview (Zero bleed)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9.r),
                child: TeacherVideoPreview(
                  path: video.path,
                  title: details.title,
                  segments: video.segments,
                ),
              ),
            ),
          ),

          // Metrics Strip
          Container(
            margin: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(
                    Icons.video_file_outlined,
                    size: 14.w,
                    color: const Color(0xFF64748B),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '$mbSize MB',
                    style: AppTextStyles.interMedium16.copyWith(
                      fontSize: 11.sp,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 12.h,
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    color: const Color(0xFFCBD5E1),
                  ),
                  Icon(
                    Icons.bookmark_outline,
                    size: 14.w,
                    color: const Color(0xFF64748B),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${video.segments.length} Checkpoints',
                    style: AppTextStyles.interMedium16.copyWith(
                      fontSize: 11.sp,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  if (isPublished) ...[
                    Container(
                      width: 1.w,
                      height: 12.h,
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      color: const Color(0xFFCBD5E1),
                    ),
                    Icon(
                      Icons.check_circle_outline,
                      size: 14.w,
                      color: const Color(0xFF16A34A),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Live on Lesson',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 10.5.sp,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
