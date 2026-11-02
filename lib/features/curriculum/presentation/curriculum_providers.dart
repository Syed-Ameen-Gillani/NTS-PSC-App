import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/curriculum/data/curriculum_repository.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';

final curriculumContextProvider = FutureProvider.autoDispose
    .family<CurriculumContext, CurriculumScope>((ref, scope) {
      ref.watch(
        authControllerProvider.select((state) => state.value?.user?.id),
      );
      return ref.read(curriculumRepositoryProvider).resolve(scope);
    });
final curriculumMaterialsProvider = FutureProvider.autoDispose
    .family<List<CurriculumMaterial>, CurriculumScope>((ref, scope) {
      ref.watch(authControllerProvider.select((s) => s.value?.user?.id));
      return ref.watch(curriculumRepositoryProvider).materials(scope);
    });
final curriculumAssessmentsProvider = FutureProvider.autoDispose
    .family<List<CurriculumAssessment>, CurriculumScope>((ref, scope) {
      ref.watch(authControllerProvider.select((s) => s.value?.user?.id));
      return ref.watch(curriculumRepositoryProvider).assessments(scope);
    });

class CurriculumAttachmentSummary {
  const CurriculumAttachmentSummary({
    required this.handouts,
    required this.quizzes,
    required this.assignments,
  });

  final int handouts;
  final int quizzes;
  final int assignments;

  bool get isEmpty => handouts == 0 && quizzes == 0 && assignments == 0;

  String get label => [
    if (handouts > 0) '$handouts ${handouts == 1 ? 'handout' : 'handouts'}',
    if (quizzes > 0) '$quizzes ${quizzes == 1 ? 'quiz' : 'quizzes'}',
    if (assignments > 0)
      '$assignments ${assignments == 1 ? 'assignment' : 'assignments'}',
  ].join('  ·  ');
}

final curriculumAttachmentSummaryProvider = FutureProvider.autoDispose
    .family<CurriculumAttachmentSummary, CurriculumScope>((ref, scope) async {
      final context = await ref.watch(curriculumContextProvider(scope).future);
      final results = await Future.wait([
        ref.watch(curriculumMaterialsProvider(context.scope).future),
        ref.watch(curriculumAssessmentsProvider(context.scope).future),
      ]);
      final materials = results[0] as List<CurriculumMaterial>;
      final assessments = results[1] as List<CurriculumAssessment>;
      return CurriculumAttachmentSummary(
        handouts: materials.length,
        quizzes: assessments.where((item) => item.kind == 'quiz').length,
        assignments: assessments
            .where((item) => item.kind == 'assignment')
            .length,
      );
    });

typedef PlacedCurriculumAssessment = ({
  CurriculumAssessment assessment,
  CurriculumScope scope,
});

/// Exact placement scope; broader work has its own module/course destination.
final curriculumVisibleAssessmentsProvider = FutureProvider.autoDispose
    .family<List<PlacedCurriculumAssessment>, CurriculumScope>((
      ref,
      scope,
    ) async {
      final context = await ref.watch(curriculumContextProvider(scope).future);
      final resolved = context.scope;
      final courseId = resolved.courseId;
      if (courseId == null) return const [];
      final scopes = <CurriculumScope>[resolved];
      final repository = ref.read(curriculumRepositoryProvider);
      final results = await Future.wait(scopes.map(repository.assessments));
      return [
        for (var i = 0; i < scopes.length; i++)
          for (final assessment in results[i])
            (assessment: assessment, scope: scopes[i]),
      ];
    });
final curriculumCandidatesProvider = FutureProvider.autoDispose
    .family<List<CurriculumAssessment>, String>(
      (ref, id) => ref.watch(curriculumRepositoryProvider).candidates(id),
    );
final curriculumMaterialUrlProvider = FutureProvider.autoDispose
    .family<Uri, CurriculumMaterial>((ref, item) {
      ref.watch(authControllerProvider.select((s) => s.value?.user?.id));
      return ref.read(curriculumRepositoryProvider).url(item);
    });
final curriculumQuizProvider = FutureProvider.autoDispose
    .family<QuizModel?, String>(
      (ref, id) => ref.read(quizRepositoryProvider).getQuizById(id),
    );
final curriculumCourseProvider = FutureProvider.autoDispose
    .family<CourseModel?, String>(
      (ref, id) => ref.read(courseRepositoryProvider).getCourseById(id),
    );

final curriculumActionsProvider = StateNotifierProvider.autoDispose
    .family<CurriculumActions, bool, CurriculumScope>(
      (ref, scope) => CurriculumActions(
        ref.read(curriculumRepositoryProvider),
        scope,
        () {
          if (!ref.mounted) return;
          ref.invalidate(curriculumMaterialsProvider(scope));
          ref.invalidate(curriculumAssessmentsProvider(scope));
        },
        () {
          if (!ref.mounted) return;
          ref.invalidate(teacherControllerProvider);
          ref.invalidate(assignmentsControllerProvider);
        },
      ),
    );

class CurriculumActions extends StateNotifier<bool> {
  CurriculumActions(this.repository, this.scope, this.refresh, this.onUnlink)
    : super(false);
  final CurriculumRepository repository;
  final CurriculumScope scope;
  final void Function() refresh;
  final void Function() onUnlink;
  bool _alive = true;
  Future<void> _run(Future<void> Function() action) async {
    if (state) return;
    state = true;
    try {
      await action();
    } finally {
      if (_alive) {
        state = false;
        refresh();
      }
    }
  }

  Future<void> upload(List<PendingMaterial> files) => _run(() async {
    for (final file in files) {
      await repository.upload(scope, file);
    }
  });
  Future<void> delete(CurriculumMaterial file) =>
      _run(() => repository.delete(file));
  Future<void> link(CurriculumAssessment item) =>
      _run(() => repository.link(scope, item));
  Future<void> unlink(String id) => _run(() async {
    await repository.unlink(id);
    onUnlink();
  });
  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }
}
