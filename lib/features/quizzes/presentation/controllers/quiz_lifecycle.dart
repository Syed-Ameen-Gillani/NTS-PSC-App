import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quiz_session_controller.dart';

final quizLifecycleProvider = Provider.autoDispose.family<void, QuizModel>((
  ref,
  quiz,
) {
  final lifecycle = AppLifecycleListener(
    onResume: () {
      if (ref.mounted) {
        ref.read(quizSessionProvider(quiz).notifier).refreshDeadline();
      }
    },
  );
  ref.onDispose(lifecycle.dispose);
});
