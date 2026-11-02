import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';
import 'package:nts_psc_app/features/learn/domain/lesson_navigation_item.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/learning_outcome_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/live_lesson_player_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/hosted_lesson_player.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/source_video_player.dart';

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState();
}

const _activities = [
  LessonActivity(
    id: 'quiz',
    kind: 'quiz',
    title: 'Knowledge check',
    order: 2,
    isRequired: true,
  ),
  LessonActivity(
    id: 'reading',
    kind: 'reading',
    title: 'Read introduction',
    order: 0,
    isRequired: true,
  ),
  LessonActivity(
    id: 'pdf',
    kind: 'material',
    title: 'Lesson handbook',
    order: 1,
    isRequired: true,
  ),
  LessonActivity(
    id: 'assignment',
    kind: 'assignment',
    title: 'Written exercise',
    order: 3,
    isRequired: true,
  ),
];

CourseModel _course({bool lockedLast = false}) => CourseModel(
  id: 'course',
  title: 'Course',
  author: '',
  rating: 0,
  price: 'Free',
  imagePath: '',
  modules: [
    CourseModuleModel(
      id: 'module',
      title: 'First module',
      lessons: [
        LessonModel(
          id: 'lesson',
          title: 'Introduction',
          durationMinutes: 10,
          activities: _activities,
        ),
      ],
    ),
    CourseModuleModel(
      id: 'module-2',
      title: 'Second module',
      lessons: [
        LessonModel(
          id: 'last',
          title: 'Final reading',
          durationMinutes: 5,
          isLocked: lockedLast,
          activities: [
            const LessonActivity(
              id: 'last-reading',
              kind: 'reading',
              title: 'Final reading',
              order: 0,
              isRequired: true,
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  Finder navigationButton(String label) => find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == label,
  );
  test(
    'ordered outline includes every content kind across module boundaries',
    () {
      final course = _course();
      final video = LessonModel(
        id: 'video-lesson',
        title: 'Video lesson',
        durationMinutes: 5,
        videoPath: 'video.mp4',
        activities: [
          const LessonActivity(
            id: 'video',
            kind: 'video',
            title: 'Video',
            order: -1,
            isRequired: true,
          ),
          ..._activities,
        ],
      );
      final items = LessonNavigationItem.fromCourse(
        course.copyWith(
          modules: [
            CourseModuleModel(
              id: 'video-module',
              title: 'Video module',
              lessons: [video],
            ),
            ...course.modules,
          ],
        ),
      );
      expect(items.take(5).map((item) => item.activity?.kind), [
        'video',
        'reading',
        'material',
        'quiz',
        'assignment',
      ]);
      expect(items.first.isVideo, isTrue);
      expect(items.skip(1).every((item) => !item.isVideo), isTrue);
      expect(items.last.moduleId, 'module-2');
    },
  );

  for (final lockedLast in [false, true]) {
    testWidgets(
      'arrows visit each activity and respect boundaries; locked=$lockedLast',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authControllerProvider.overrideWith(_Auth.new),
              learningOutcomeProvider.overrideWith(
                (ref, id) async => {'completed': false, 'activities': []},
              ),
              learningEvidenceChangesProvider.overrideWith(
                (ref) => const Stream.empty(),
              ),
            ],
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, _) => MaterialApp(
                home: LiveLessonPlayerScreen(
                  course: _course(lockedLast: lockedLast),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<IconButton>(navigationButton('Previous item'))
              .onPressed,
          isNull,
        );
        final labels = ['Open handout', 'Open quiz', 'Open assignment'];
        for (var i = 0; i < labels.length; i++) {
          await tester.tap(find.byTooltip('Next item'));
          await tester.pumpAndSettle();
          expect(find.text(labels[i]), findsOneWidget);
          expect(find.text('Item ${i + 2} of 5'), findsOneWidget);
          expect(find.byType(HostedLessonPlayer), findsNothing);
          expect(find.byType(SourceVideoPlayer), findsNothing);
        }
        if (lockedLast) {
          expect(
            tester.widget<IconButton>(navigationButton('Next item')).onPressed,
            isNull,
          );
        } else {
          await tester.tap(find.byTooltip('Next item'));
          await tester.pumpAndSettle();
          expect(find.text('Item 5 of 5'), findsOneWidget);
          expect(
            tester.widget<IconButton>(navigationButton('Next item')).onPressed,
            isNull,
          );
        }
        await tester.tap(find.byTooltip('Previous item'));
        await tester.pumpAndSettle();
        expect(
          find.text(lockedLast ? 'Item 3 of 5' : 'Item 4 of 5'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
