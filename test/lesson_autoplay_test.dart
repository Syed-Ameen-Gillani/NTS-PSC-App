import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, AuthClientOptions;
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/data/video_study_repository.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_access_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_source_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/live_lesson_player_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/video_fullscreen_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';

import 'support/fake_video_controller.dart';
import 'support/memory_video_study_repository.dart';

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState(
    isAuthenticated: true,
    user: UserModel(
      id: 'student',
      name: 'Student',
      email: 'test@example.invalid',
      imagePath: '',
      isPremium: false,
      courses: 0,
      quizzes: 0,
      avgScore: 0,
    ),
  );
}

class _Progress extends MyLearningController {
  _Progress(this.fail);
  final bool fail;
  final completed = <String>[];
  @override
  MyLearningState build() => MyLearningState();
  @override
  Future<void> markLessonCompleted(String courseId, String lessonId) async {
    if (fail) throw StateError('Test network failure');
    completed.add(lessonId);
  }
}

class _Evidence extends LearningEvidenceRepository {
  _Evidence()
    : super(
        SupabaseClient(
          'https://example.invalid',
          'key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  @override
  String? get user => 'student';
  @override
  Future<void> sync() async {}
  @override
  Future<Map<String, dynamic>?> videoSession(
    String lesson, {
    String? source,
  }) async => null;
  @override
  Future<Map<String, dynamic>> outcome(String lesson) async => {
    'completed': false,
    'activities': <dynamic>[],
  };
}

void main() {
  for (final scenario in [
    'advance',
    'fullscreen',
    'disabled',
    'locked',
    'server locked',
    'save failure',
  ]) {
    testWidgets('lesson completion/autoplay: $scenario', (tester) async {
      tester.view.physicalSize = const Size(375, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final first = FakeVideoController();
      final second = FakeVideoController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final progress = _Progress(scenario == 'save failure');
      final course = CourseModel(
        id: 'course',
        title: 'Course',
        author: 'Teacher',
        rating: 0,
        price: 'Free',
        imagePath: '',
        modules: [
          CourseModuleModel(
            id: 'module',
            title: 'Module',
            lessons: [
              LessonModel(
                id: 'first',
                title: 'First lesson',
                durationMinutes: 2,
                videoUrl: 'https://example.invalid/first.mp4',
              ),
              LessonModel(
                id: 'second',
                title: 'Second lesson',
                durationMinutes: 2,
                videoUrl: 'https://example.invalid/second.mp4',
                isLocked: scenario == 'locked',
              ),
            ],
          ),
        ],
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => LiveLessonPlayerScreen(course: course),
          ),
          GoRoute(
            path: AppRoute.videoFullscreen.path,
            name: AppRoute.videoFullscreen.name,
            pageBuilder: (_, state) => NoTransitionPage(
              child: VideoFullscreenScreen(
                session: state.extra as VideoPlayerSession,
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_Auth.new),
            learningEvidenceRepositoryProvider.overrideWithValue(_Evidence()),
            lessonAccessCourseProvider.overrideWith(
              (ref, id) async => scenario == 'save failure'
                  ? throw StateError('offline')
                  : scenario == 'server locked'
                  ? course.copyWith(
                      modules: [
                        CourseModuleModel(
                          id: 'module',
                          title: 'Module',
                          lessons: [
                            course.modules.single.lessons.first,
                            course.modules.single.lessons.last.copyWith(
                              isLocked: true,
                            ),
                          ],
                        ),
                      ],
                    )
                  : course,
            ),
            myLearningControllerProvider.overrideWith(() => progress),
            videoStudyRepositoryProvider.overrideWithValue(
              MemoryVideoStudyRepository(),
            ),
            videoSourceProvider.overrideWith(
              (ref, source) async =>
                  source.location.contains('first') ? first : second,
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (scenario != 'disabled') {
        await tester.ensureVisible(find.text('Autoplay'));
        await tester.tap(find.text('Autoplay'));
        await tester.pumpAndSettle();
      }
      if (scenario == 'fullscreen') {
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(ProfessionalVideoPlayer));
        // Scrolling through the lesson can let the playback overlay auto-hide.
        // Reveal it just as a viewer would before entering fullscreen.
        if (find.byTooltip('Fullscreen').evaluate().isEmpty) {
          await tester.tapAt(
            tester.getTopLeft(find.byType(ProfessionalVideoPlayer)) +
                const Offset(8, 64),
          );
          await tester.pump();
        }
        await tester.ensureVisible(find.byTooltip('Fullscreen'));
        await tester.tap(find.byTooltip('Fullscreen'));
        await tester.pumpAndSettle();
      }
      first.value = first.value.copyWith(
        position: first.value.duration,
        isPlaying: false,
      );
      await tester.pumpAndSettle();
      if (scenario == 'advance' || scenario == 'fullscreen') {
        expect(progress.completed, isEmpty);
        expect(second.value.isPlaying, true);
      } else {
        expect(second.value.isPlaying, false);
        expect(progress.completed, isEmpty);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
