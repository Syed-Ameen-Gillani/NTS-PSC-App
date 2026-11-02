import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';

final learningEvidenceChangesProvider = StreamProvider<String>(
  (ref) => LearningEvidenceRepository.changes.stream,
);

final learningOutcomeProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) {
      ref.watch(authControllerProvider.select((s) => s.value?.user?.id));
      final subscription = LearningEvidenceRepository.changes.stream
          .where((lesson) => lesson == id)
          .listen((_) => ref.invalidateSelf());
      ref.onDispose(subscription.cancel);
      return ref.read(learningEvidenceRepositoryProvider).outcome(id);
    });
final learningEvidenceMessageProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, id) {
      ref.watch(authControllerProvider.select((s) => s.value?.user?.id));
      final timer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => ref.invalidateSelf(),
      );
      ref.onDispose(timer.cancel);
      return ref.read(learningEvidenceRepositoryProvider).pendingMessage(id);
    });
