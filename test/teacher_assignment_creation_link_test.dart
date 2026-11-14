import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/pages/teacher_create_assignment_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/curriculum/data/curriculum_repository.dart';
import 'package:nts_psc_app/features/curriculum/domain/assessment_creation_request.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

const scope = CurriculumScope(courseId: 'course', lessonId: 'lesson');

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState(selectedRole: UserRole.teacher);
}

class _Teacher extends TeacherController {
  @override
  FutureOr<TeacherState> build() => TeacherState(
    stats: TeacherStatsModel(
      totalStudents: 0,
      activeCourses: 1,
      totalQuizzes: 0,
      avgRating: 0,
      totalEarnings: '',
    ),
    courses: [
      CourseModel(
        id: 'course',
        title: 'Kashmir studies',
        author: 'Teacher',
        rating: 0,
        price: 'Free',
        imagePath: '',
      ),
    ],
  );
}

class _Assignments extends AssignmentsController {
  static int creates = 0;

  @override
  FutureOr<AssignmentsState> build() => const AssignmentsState();

  @override
  Future<AssignmentModel> createAssignment({
    required String courseId,
    required String courseTitle,
    required String title,
    required String instructions,
    String? externalUrl,
    required DateTime dueAt,
    List<AssignmentAttachmentModel> attachments = const [],
  }) async {
    creates++;
    expect(courseId, 'course');
    return AssignmentModel(
      id: 'created',
      courseId: courseId,
      courseTitle: courseTitle,
      title: title,
      instructions: instructions,
      dueAt: dueAt,
      isPublished: false,
    );
  }
}

class _Curriculum extends CurriculumRepository {
  _Curriculum(this.fail, {this.linkGate})
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final bool fail;
  final Completer<void>? linkGate;
  int links = 0;

  @override
  Future<void> link(CurriculumScope target, CurriculumAssessment item) async {
    links++;
    expect(target, scope);
    expect(item.assessmentId, 'created');
    if (linkGate != null) await linkGate!.future;
    if (fail) throw StateError('Link failed');
  }
}

Future<void> _openForm(
  WidgetTester tester,
  _Curriculum repository, {
  bool canManage = true,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/create'),
            child: const Text('Open form'),
          ),
        ),
      ),
      GoRoute(
        path: '/create',
        builder: (_, _) => const TeacherCreateAssignmentScreen(
          creationRequest: AssessmentCreationRequest(scope),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        teacherControllerProvider.overrideWith(_Teacher.new),
        assignmentsControllerProvider.overrideWith(_Assignments.new),
        curriculumContextProvider(scope).overrideWith(
          (ref) async => CurriculumContext(
            scope: scope,
            title: 'Lesson',
            courseTitle: 'Kashmir studies',
            canManage: canManage,
          ),
        ),
        curriculumRepositoryProvider.overrideWithValue(repository),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.tap(find.text('Open form'));
  await tester.pumpAndSettle();
}

Future<void> _fillAndSave(WidgetTester tester) async {
  final title = find.byWidgetPredicate(
    (widget) =>
        widget is CustomTextFormField &&
        widget.hintText == 'e.g. Customs Act case study',
  );
  final instructions = find.byWidgetPredicate(
    (widget) =>
        widget is CustomTextFormField &&
        widget.hintText == 'Describe the task and expected answer',
  );
  await tester.enterText(title, 'Read chapter one');
  await tester.enterText(instructions, 'Summarize the chapter.');
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  final dueDate = find.byWidgetPredicate(
    (widget) =>
        widget is CustomTextFormField && widget.hintText == 'Select a due date',
  );
  await tester.ensureVisible(dueDate);
  await tester.pumpAndSettle();
  await tester.tap(dueDate);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byType(CustomButton));
  await tester.tap(find.byType(CustomButton));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => _Assignments.creates = 0);

  test('a concurrent link reports busy instead of false success', () async {
    final gate = Completer<void>();
    final repository = _Curriculum(false, linkGate: gate);
    final actions = CurriculumActions(repository, scope, () {}, () {});
    addTearDown(actions.dispose);
    const assessment = CurriculumAssessment(
      id: 'created',
      assessmentId: 'created',
      title: 'Read chapter one',
      kind: 'assignment',
      status: 'draft',
    );
    final first = actions.link(assessment);
    await expectLater(actions.link(assessment), throwsA(isA<StateError>()));
    expect(repository.links, 1);
    gate.complete();
    await first;
  });

  testWidgets('lesson assignment uses its fixed course and links once', (
    tester,
  ) async {
    final repository = _Curriculum(false);
    await _openForm(tester, repository);
    expect(find.text('Kashmir studies'), findsOneWidget);
    expect(find.text('Select a course'), findsNothing);
    await _fillAndSave(tester);
    expect(_Assignments.creates, 1);
    expect(repository.links, 1);
    expect(find.text('Open form'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets(
    'a failed link keeps one saved draft and reports partial success',
    (tester) async {
      final repository = _Curriculum(true);
      await _openForm(tester, repository);
      await _fillAndSave(tester);
      expect(_Assignments.creates, 1);
      expect(repository.links, 1);
      expect(find.text('Open form'), findsOneWidget);
      expect(
        find.textContaining('Draft saved, but linking failed'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets('cannot create when the lesson is no longer manageable', (
    tester,
  ) async {
    final repository = _Curriculum(false);
    await _openForm(tester, repository, canManage: false);
    await _fillAndSave(tester);
    expect(_Assignments.creates, 0);
    expect(repository.links, 0);
    expect(
      find.textContaining('Selected lesson is unavailable'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
  });
}
