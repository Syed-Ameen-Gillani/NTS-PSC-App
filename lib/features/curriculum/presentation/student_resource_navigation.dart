import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_access_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/learning_outcome_provider.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import '../domain/curriculum_models.dart';
import '../domain/lesson_activity.dart';
import 'curriculum_providers.dart';

Future<void> openStudentMaterial(
  BuildContext context,
  WidgetRef ref,
  CurriculumScope scope,
  CurriculumMaterial file,
) async {
  try {
    if (scope.lessonId != null &&
        {'pdf', 'txt'}.contains(materialExtension(file.path))) {
      developer.log(
        'Opening in-app material: lesson=${scope.lessonId}, '
        'material=${file.id}, extension=${materialExtension(file.path)}.',
        name: 'CBOA.Reading',
      );
      await context.pushNamed(
        AppRoute.lessonReading.name,
        queryParameters: {
          'lessonId': scope.lessonId!,
          'materialId': file.id,
          'title': file.title,
        },
      );
      developer.log(
        'Returned from in-app material ${file.id}.',
        name: 'CBOA.Reading',
      );
    } else {
      final url = await ref.read(curriculumMaterialUrlProvider(file).future);
      if (!context.mounted) return;
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw StateError('No viewer');
      }
    }
  } catch (error, stackTrace) {
    developer.log(
      'Material navigation failed: material=${file.id}.',
      name: 'CBOA.Reading',
      error: error,
      stackTrace: stackTrace,
    );
    if (context.mounted) {
      CustomToast.showError(
        context,
        message: 'Could not open this file. Try again.',
      );
    }
  }
}

Future<void> openStudentAssessment(
  BuildContext context,
  WidgetRef ref,
  CurriculumScope scope,
  CurriculumAssessment item,
) async {
  await context.pushNamed(
    item.kind == 'quiz'
        ? AppRoute.activeQuiz.name
        : AppRoute.studentAssignment.name,
    queryParameters: {
      item.kind == 'quiz' ? 'quizId' : 'assignmentId': item.assessmentId,
    },
  );
  if (!context.mounted) return;
  if (scope.lessonId != null) {
    ref.invalidate(learningOutcomeProvider(scope.lessonId!));
  }
  if (scope.courseId != null) {
    ref.invalidate(lessonAccessCourseProvider(scope.courseId!));
  }
}

/// Resolve exact source IDs through the existing authorized, lesson-scoped
/// providers only when tapped. Never infer a destination from a title.
Future<void> openStudentActivity(
  BuildContext context,
  WidgetRef ref,
  CurriculumScope scope,
  LessonActivity activity,
) async {
  try {
    developer.log(
      'Opening curriculum activity: lesson=${scope.lessonId}, '
      'activity=${activity.id}, kind=${activity.kind}.',
      name: 'CBOA.Reading',
    );
    switch (activity.kind) {
      case 'reading':
        await context.pushNamed(
          AppRoute.lessonReading.name,
          queryParameters: {'lessonId': scope.lessonId!},
        );
      case 'material':
        final files = await ref.read(curriculumMaterialsProvider(scope).future);
        if (!context.mounted) return;
        final file = files
            .where((f) => f.id == activity.materialId)
            .firstOrNull;
        if (file == null) throw StateError('Material unavailable');
        await openStudentMaterial(context, ref, scope, file);
      case 'quiz':
      case 'assignment':
        final items = await ref.read(
          curriculumAssessmentsProvider(scope).future,
        );
        if (!context.mounted) return;
        final item = items
            .where(
              (item) =>
                  item.id == activity.assessmentLinkId &&
                  item.kind == activity.kind &&
                  item.status == 'published',
            )
            .firstOrNull;
        if (item == null) throw StateError('Assessment unavailable');
        await openStudentAssessment(context, ref, scope, item);
    }
  } catch (error, stackTrace) {
    developer.log(
      'Curriculum activity navigation failed: activity=${activity.id}, '
      'kind=${activity.kind}.',
      name: 'CBOA.Reading',
      error: error,
      stackTrace: stackTrace,
    );
    if (context.mounted) {
      CustomToast.showError(
        context,
        message: 'Could not open this activity. Try again.',
      );
    }
  }
}
