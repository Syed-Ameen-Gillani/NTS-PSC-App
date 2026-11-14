import 'learning_outcome_provider.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'lesson_access_provider.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/utils/background_return_observer.dart';
import 'package:nts_psc_app/core/utils/lifecycle_diagnostics.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/learn/data/learning_activity_repository.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quizzes_controller.dart';

final learningActivitySyncProvider = Provider<void>((ref) {
  if (!AppConfig.isSupabaseEnabled) return;
  final identity = ref.watch(
    authControllerProvider.select(
      (state) => (state.value?.user?.id, state.value?.user?.role),
    ),
  );
  final userId = identity.$1;
  if (userId == null || identity.$2 != UserRole.student) return;
  final repository = ref.read(learningActivityRepositoryProvider);
  Timer? debounce;
  void refresh() {
    if (!ref.mounted) return;
    LifecycleDiagnostics.event('learning-refresh', 'reason=realtime-change');
    ref.invalidate(lessonAccessCourseProvider);
    ref.invalidate(learningOutcomeProvider);
    ref.invalidate(curriculumAssessmentsProvider);
    ref.invalidate(myLearningControllerProvider);
    ref.invalidate(assignmentsControllerProvider);
    ref.invalidate(quizzesControllerProvider);
    ref.invalidate(homeControllerProvider);
  }

  final evidence = ref.read(learningEvidenceRepositoryProvider);
  unawaited(evidence.sync());
  final periodic = Timer.periodic(
    const Duration(seconds: 30),
    (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(evidence.sync());
      }
    },
  );
  final subscription = LearningEvidenceRepository.changes.stream.listen((_) {
    LifecycleDiagnostics.event('learning-refresh', 'reason=confirmed-evidence');
    if (ref.mounted) ref.invalidate(myLearningControllerProvider);
  });
  ref.onDispose(() {
    periodic.cancel();
    unawaited(subscription.cancel());
  });
  final channel = repository.subscribe(userId, () {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), refresh);
  });
  final lifecycle = BackgroundReturnObserver(() {
    if (!ref.mounted) return;
    LifecycleDiagnostics.event('learning-sync', 'reason=background-return');
    // Empty queues make no network calls. Confirmed changes already notify
    // the evidence stream/realtime listeners; resuming alone changes no data.
    unawaited(evidence.sync());
  });
  WidgetsBinding.instance.addObserver(lifecycle);
  ref.onDispose(() {
    debounce?.cancel();
    WidgetsBinding.instance.removeObserver(lifecycle);
    unawaited(repository.unsubscribe(channel));
  });
});
