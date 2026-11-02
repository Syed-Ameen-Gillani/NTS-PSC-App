import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/pages/student_assignment_screen.dart';
import 'package:nts_psc_app/features/assignments/presentation/pages/teacher_create_assignment_screen.dart';
import 'package:nts_psc_app/features/assignments/presentation/pages/teacher_review_assignment_screen.dart';
import 'package:nts_psc_app/features/home/presentation/pages/course_detail_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/lesson_player_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/active_quiz_screen.dart';

final _notificationCourseProvider = FutureProvider.autoDispose
    .family<CourseModel?, String>((ref, id) {
      ref.watch(
        authControllerProvider.select((value) => value.value?.user?.id),
      );
      return ref.read(courseRepositoryProvider).getCourseById(id);
    });

final _notificationQuizProvider = FutureProvider.family<QuizModel?, String>(
  (ref, id) => ref.read(quizRepositoryProvider).getQuizById(id),
);

final _notificationAssignmentProvider =
    FutureProvider.family<AssignmentModel?, String>((ref, id) async {
      final state = await ref.read(assignmentsControllerProvider.future);
      return state.assignments.where((item) => item.id == id).firstOrNull;
    });

class NotificationCoursePage extends ConsumerWidget {
  const NotificationCoursePage({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _ResourceState<CourseModel>(
        value: ref.watch(_notificationCourseProvider(courseId)),
        onRetry: () => ref.invalidate(_notificationCourseProvider(courseId)),
        builder: (course) => CourseDetailScreen(course: course),
      );
}

class NotificationAssignmentPage extends ConsumerWidget {
  const NotificationAssignmentPage({
    super.key,
    required this.assignmentId,
    this.teacherReview = false,
  });

  final String assignmentId;
  final bool teacherReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _ResourceState<AssignmentModel>(
        value: ref.watch(_notificationAssignmentProvider(assignmentId)),
        onRetry: () =>
            ref.invalidate(_notificationAssignmentProvider(assignmentId)),
        builder: (assignment) => teacherReview
            ? assignment.isPublished
                  ? TeacherReviewAssignmentScreen(assignment: assignment)
                  : TeacherCreateAssignmentScreen(assignment: assignment)
            : StudentAssignmentScreen(assignment: assignment),
      );
}

class NotificationQuizPage extends ConsumerWidget {
  const NotificationQuizPage({super.key, required this.quizId});
  final String quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _ResourceState<QuizModel>(
        value: ref.watch(_notificationQuizProvider(quizId)),
        onRetry: () => ref.invalidate(_notificationQuizProvider(quizId)),
        builder: (quiz) => ActiveQuizScreen(quiz: quiz),
      );
}

class NotificationLessonPage extends ConsumerWidget {
  const NotificationLessonPage({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  final String courseId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _ResourceState<CourseModel>(
        value: ref.watch(_notificationCourseProvider(courseId)),
        onRetry: () => ref.invalidate(_notificationCourseProvider(courseId)),
        builder: (course) {
          LessonModel? lesson;
          for (final module in course.modules) {
            lesson = module.lessons
                .where((item) => item.id == lessonId)
                .firstOrNull;
            if (lesson != null) break;
          }
          if (lesson == null) return const _UnavailableResource();
          return LessonPlayerScreen(course: course, initialLesson: lesson);
        },
      );
}

class _ResourceState<T> extends StatelessWidget {
  const _ResourceState({
    required this.value,
    required this.builder,
    required this.onRetry,
  });

  final AsyncValue<T?> value;
  final Widget Function(T value) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () =>
        const AppScaffold(body: Center(child: CircularProgressIndicator())),
    error: (_, _) => _UnavailableResource(onRetry: onRetry),
    data: (resource) =>
        resource == null ? const _UnavailableResource() : builder(resource),
  );
}

class _UnavailableResource extends StatelessWidget {
  const _UnavailableResource({this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => AppScaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(),
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, color: AppColors.grey400, size: 36.w),
            SizedBox(height: 12.h),
            Text(
              'This item is unavailable or you no longer have access.',
              textAlign: TextAlign.center,
              style: AppTextStyles.interRegular16,
            ),
            if (onRetry != null) ...[
              SizedBox(height: 12.h),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
