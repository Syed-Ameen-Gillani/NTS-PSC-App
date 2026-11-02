import 'learning_outcome_provider.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'lesson_access_provider.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final user = ref.watch(authControllerProvider).value?.user;
  if (user == null || user.role != UserRole.student) return;
  final repository = LearningActivityRepository(Supabase.instance.client);
  Timer? debounce;
  void refresh() {
    if (!ref.mounted) return;
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
    (_) => unawaited(evidence.sync()),
  );
  final subscription = LearningEvidenceRepository.changes.stream.listen((_) {
    if (ref.mounted) ref.invalidate(myLearningControllerProvider);
  });
  ref.onDispose(() {
    periodic.cancel();
    unawaited(subscription.cancel());
  });
  final channel = repository.subscribe(user.id, () {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), refresh);
  });
  final lifecycle = AppLifecycleListener(
    onResume: () async {
      await evidence.sync();
      refresh();
    },
  );
  ref.onDispose(() {
    debounce?.cancel();
    lifecycle.dispose();
    unawaited(repository.unsubscribe(channel));
  });
});
