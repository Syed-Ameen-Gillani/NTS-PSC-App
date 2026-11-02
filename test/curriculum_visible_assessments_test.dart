import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/curriculum/data/curriculum_repository.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, AuthClientOptions;

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState();
}

class _Curriculum extends CurriculumRepository {
  _Curriculum()
    : super(
        SupabaseClient(
          'https://example.invalid',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final requested = <CurriculumScope>[];

  @override
  Future<CurriculumContext> resolve(CurriculumScope scope) async =>
      const CurriculumContext(
        scope: CurriculumScope(
          courseId: 'course',
          moduleId: 'module',
          lessonId: 'lesson',
        ),
        title: 'Lesson',
        courseTitle: 'Course',
        canManage: true,
      );

  @override
  Future<List<CurriculumAssessment>> assessments(CurriculumScope scope) async {
    requested.add(scope);
    final placement = scope.targetLabel.toLowerCase();
    return [
      CurriculumAssessment(
        id: '$placement-link',
        assessmentId: '$placement-quiz',
        title: '$placement quiz',
        kind: 'quiz',
        status: 'published',
      ),
    ];
  }

  @override
  Future<List<CurriculumMaterial>> materials(CurriculumScope scope) async => [
    const CurriculumMaterial(
      id: 'handout',
      title: 'Notes.pdf',
      path: 'notes.pdf',
      sizeBytes: 10,
    ),
  ];
}

void main() {
  test('lesson studio includes only exact lesson assessment links', () async {
    final repository = _Curriculum();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        curriculumRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    const scope = CurriculumScope(lessonId: 'lesson');
    final items = await container.read(
      curriculumVisibleAssessmentsProvider(scope).future,
    );

    expect(items.map((item) => item.assessment.title), ['lesson quiz']);
    expect(items.map((item) => item.scope.targetLabel), ['Lesson']);
    expect(repository.requested.length, 1);
    expect(
      repository.requested.every((scope) => scope.courseId == 'course'),
      isTrue,
    );
  });

  test('lesson summary includes only direct lesson attachments', () async {
    final repository = _Curriculum();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        curriculumRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final summary = await container.read(
      curriculumAttachmentSummaryProvider(
        const CurriculumScope(lessonId: 'lesson'),
      ).future,
    );

    expect(summary.label, '1 handout  ·  1 quiz');
    expect(repository.requested, [
      const CurriculumScope(
        courseId: 'course',
        moduleId: 'module',
        lessonId: 'lesson',
      ),
    ]);
  });
}
