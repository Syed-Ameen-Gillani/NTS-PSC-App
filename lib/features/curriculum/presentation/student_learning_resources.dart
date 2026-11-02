import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_access_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/learning_outcome_provider.dart';
import '../domain/curriculum_models.dart';
import 'curriculum_providers.dart';
import 'student_resource_navigation.dart';

/// A module lists ordered lessons and its own work. Lesson resources never
/// inherit course/module attachments or videos.
class StudentLearningResources extends ConsumerWidget {
  const StudentLearningResources({super.key, required this.details});
  final CurriculumContext details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = details.scope;
    final outcome = scope.lessonId == null
        ? null
        : ref.watch(learningOutcomeProvider(scope.lessonId!));
    String stateFor(CurriculumAssessment item) {
      if (scope.lessonId == null) {
        return item.kind == 'quiz' ? 'Quiz' : 'Assignment';
      }
      final activities = (outcome?.value?['activities'] as List? ?? [])
          .cast<Map>();
      final activity = activities
          .where((a) => a['assessment_link_id'] == item.id)
          .firstOrNull;
      return switch (activity?['state']) {
        'submitted' => 'Awaiting review',
        'rejected' => 'Needs revision',
        'failed' => 'Try again',
        'waived' => 'Optional for your current progress',
        'completed' => item.kind == 'quiz' ? 'Passed' : 'Approved',
        'available' => 'Not started',
        _ => 'Check progress online',
      };
    }

    final materials = ref.watch(curriculumMaterialsProvider(scope));
    final assessments = ref.watch(curriculumAssessmentsProvider(scope));
    final courseState = scope.courseId == null
        ? null
        : ref.watch(lessonAccessCourseProvider(scope.courseId!));
    if (materials.isLoading ||
        assessments.isLoading ||
        courseState?.isLoading == true) {
      return const Center(child: CircularProgressIndicator());
    }
    if (materials.hasError ||
        assessments.hasError ||
        courseState?.hasError == true) {
      return Center(
        child: TextButton(
          onPressed: () {
            ref.invalidate(curriculumMaterialsProvider(scope));
            ref.invalidate(curriculumAssessmentsProvider(scope));
            if (scope.courseId != null) {
              ref.invalidate(lessonAccessCourseProvider(scope.courseId!));
            }
          },
          child: const Text('Could not load learning resources. Retry'),
        ),
      );
    }
    final course = courseState?.value;
    final modules =
        course?.modules.where((m) => m.id == scope.moduleId).toList() ?? [];
    final lessons = scope.lessonId == null
        ? modules.expand((m) => m.lessons).toList()
        : [];
    final lesson = course?.modules
        .expand((m) => m.lessons)
        .where((l) => l.id == scope.lessonId)
        .firstOrNull;
    final reading = lesson?.notes.trim().isNotEmpty == true;
    final files = materials.value ?? [];
    final work = (assessments.value ?? [])
        .where((a) => a.status == 'published')
        .toList();
    if (lessons.isEmpty && files.isEmpty && work.isEmpty && !reading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 40.w,
                color: AppColors.grey500,
              ),
              SizedBox(height: 12.h),
              Text(
                'No materials or assessments yet',
                style: AppTextStyles.interSemiBold16,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        Text(details.title, style: AppTextStyles.interSemiBold16),
        SizedBox(height: 16.h),
        if (lessons.isNotEmpty) ...[
          Text('Lessons', style: AppTextStyles.interSemiBold16),
          for (var i = 0; i < lessons.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                lessons[i].isLocked
                    ? Icons.lock_outline
                    : Icons.school_outlined,
              ),
              title: Text('${i + 1}. ${lessons[i].title}'),
              subtitle: Text(
                lessons[i].isCompleted
                    ? 'Completed'
                    : lessons[i].isLocked
                    ? 'Complete earlier work first'
                    : 'Available',
              ),
              onTap: lessons[i].isLocked
                  ? null
                  : () => context.pushNamed(
                      AppRoute.lessonPlayer.name,
                      queryParameters: {
                        'courseId': scope.courseId!,
                        'lessonId': lessons[i].id,
                      },
                    ),
            ),
          SizedBox(height: 16.h),
        ],
        if (files.isNotEmpty || reading) ...[
          Text(
            scope.lessonId == null
                ? '${scope.targetLabel} materials'
                : 'Materials',
            style: AppTextStyles.interSemiBold16,
          ),
          if (reading)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Lesson reading'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(
                AppRoute.lessonReading.name,
                queryParameters: {'lessonId': scope.lessonId!},
              ),
            ),
          for (final file in files)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(file.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openStudentMaterial(context, ref, scope, file),
            ),
          SizedBox(height: 16.h),
        ],
        if (work.isNotEmpty) ...[
          Text(
            scope.lessonId == null
                ? '${scope.targetLabel} assessments'
                : 'Assessments',
            style: AppTextStyles.interSemiBold16,
          ),
          for (final item in work)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                item.kind == 'quiz'
                    ? Icons.quiz_outlined
                    : Icons.assignment_outlined,
              ),
              title: Text(item.title),
              subtitle: Text(stateFor(item)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openStudentAssessment(context, ref, scope, item),
            ),
        ],
      ],
    );
  }
}
