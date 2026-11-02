import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, AuthClientOptions;
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/data/curriculum_repository.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_resources_screen.dart';

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState();
}

class _Resources extends CurriculumRepository {
  _Resources()
    : super(
        SupabaseClient(
          'https://example.invalid',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  bool manage = true;
  Completer<void>? pending;
  final linked = <CurriculumAssessment>[];
  @override
  Future<CurriculumContext> resolve(CurriculumScope scope) async =>
      CurriculumContext(
        scope: scope,
        title: 'Module 1',
        courseTitle: 'Course',
        canManage: manage,
      );
  @override
  Future<List<CurriculumMaterial>> materials(CurriculumScope scope) async => [
    const CurriculumMaterial(
      id: 'file',
      title: 'Actual lesson handout.pdf',
      path: 'private/file.pdf',
      sizeBytes: 1024,
    ),
  ];
  @override
  Future<List<CurriculumAssessment>> assessments(CurriculumScope scope) async =>
      linked.toList();
  @override
  Future<List<CurriculumAssessment>> candidates(String courseId) async => [
    const CurriculumAssessment(
      id: 'quiz',
      assessmentId: 'quiz',
      title: 'Course quiz draft',
      kind: 'quiz',
      status: 'draft',
    ),
  ];
  @override
  Future<void> link(CurriculumScope scope, CurriculumAssessment item) async {
    await pending?.future;
    linked.add(item);
  }
}

class _EmptyResources extends _Resources {
  @override
  Future<List<CurriculumMaterial>> materials(CurriculumScope scope) async => [];
}

Widget _app(_Resources repository) => ProviderScope(
  overrides: [
    curriculumRepositoryProvider.overrideWithValue(repository),
    authControllerProvider.overrideWith(_Auth.new),
  ],
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => const MaterialApp(
      home: CurriculumResourcesScreen(
        scope: CurriculumScope(courseId: 'course', moduleId: 'module'),
      ),
    ),
  ),
);

void main() {
  testWidgets('empty resources keep only the Lesson Studio FAB', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_EmptyResources()));
    await tester.pumpAndSettle();

    expect(find.text('No Resources Attached Yet'), findsOneWidget);
    expect(find.text('Open Lesson Studio'), findsNothing);
    expect(
      find.widgetWithText(FloatingActionButton, 'Lesson Studio'),
      findsOneWidget,
    );
  });
  for (final width in [320.0, 768.0]) {
    testWidgets('teacher materials remain organized and responsive at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Resources();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      expect(find.text('Actual lesson handout.pdf'), findsOneWidget);
      expect(find.text('Lesson Studio'), findsWidgets);
      expect(find.byIcon(Icons.add), findsWidgets);
      expect(find.text('Upload'), findsNothing);
      expect(find.text('ATTACHED ASSESSMENTS'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('learner does not receive teaching controls', (tester) async {
    final repository = _Resources()..manage = false;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.text('Actual lesson handout.pdf'), findsOneWidget);
    expect(find.text('Lesson Studio'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byTooltip('Delete material'), findsNothing);
  });
  testWidgets('attached assessments only display when assessments exist', (
    tester,
  ) async {
    final repository = _Resources();
    repository.linked.add(
      const CurriculumAssessment(
        id: 'quiz-1',
        assessmentId: 'quiz-1',
        title: 'Course quiz draft',
        kind: 'quiz',
        status: 'draft',
      ),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.text('ATTACHED ASSESSMENTS'), findsOneWidget);
    expect(find.text('Course quiz draft'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('•  DRAFT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled unlink keeps the attached assessment', (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Resources();
    repository.linked.add(
      const CurriculumAssessment(
        id: 'quiz-1',
        assessmentId: 'quiz-1',
        title: 'Course quiz draft',
        kind: 'quiz',
        status: 'draft',
      ),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Unlink'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Unlink'));
    await tester.pumpAndSettle();
    expect(find.text('Unlink assessment?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.linked, hasLength(1));
    expect(find.text('Course quiz draft'), findsOneWidget);
  });
}
