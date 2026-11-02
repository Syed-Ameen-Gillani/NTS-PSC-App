import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/domain/lesson_player_mode.dart';
import 'package:nts_psc_app/features/learn/domain/learning_access.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_access_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/live_lesson_player_screen.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';

class LessonAccessGate extends ConsumerStatefulWidget {
  const LessonAccessGate({
    super.key,
    required this.courseId,
    this.lessonId,
    this.mode = LessonPlayerMode.learning,
  });
  final String courseId;
  final String? lessonId;
  final LessonPlayerMode mode;
  @override
  ConsumerState<LessonAccessGate> createState() => _LessonAccessGateState();
}

class _LessonAccessGateState extends ConsumerState<LessonAccessGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(lessonAccessCourseProvider(widget.courseId));
    }
  }

  @override
  Widget build(BuildContext context) => ref
      .watch(lessonAccessCourseProvider(widget.courseId))
      .when(
        loading: () =>
            const AppScaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => _message(
          'Could not check lesson access. Please retry.',
          retry: true,
        ),
        data: (course) {
          if (ref.watch(authControllerProvider).value?.user == null) {
            return _message('Sign in to open this lesson.');
          }
          if (course == null) {
            return _message(
              ref.watch(authControllerProvider).value?.user == null
                  ? 'Sign in to open this lesson.'
                  : 'This lesson is unavailable.',
            );
          }
          final lessons = course.modules.expand((m) => m.lessons).toList();
          final LessonModel? lesson = widget.lessonId == null
              ? lessons.where((l) => !l.isLocked).firstOrNull
              : lessons.where((l) => l.id == widget.lessonId).firstOrNull;
          if (lesson == null) return _message('This lesson is unavailable.');
          final owner =
              course.instructorId ==
              ref.watch(authControllerProvider).value?.user?.id;
          if (widget.mode == LessonPlayerMode.instructorPreview && !owner) {
            return _message('Instructor preview is unavailable.');
          }
          final isPublicPreview = lesson.accessState == 'preview';
          if (lesson.isLocked ||
              (!owner && !course.hasEntitlement && !isPublicPreview)) {
            return _message(LearningAccess.message(lesson.accessState));
          }
          return LiveLessonPlayerScreen(
            course: course,
            initialLesson: lesson,
            mode: owner ? LessonPlayerMode.instructorPreview : widget.mode,
          );
        },
      );

  Widget _message(String text, {bool retry = false}) => AppScaffold(
    appBar: AppBar(),
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (retry)
              TextButton(
                onPressed: () =>
                    ref.invalidate(lessonAccessCourseProvider(widget.courseId)),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    ),
  );
}
