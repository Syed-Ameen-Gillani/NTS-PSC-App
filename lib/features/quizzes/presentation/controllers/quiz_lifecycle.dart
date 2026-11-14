import 'package:flutter/widgets.dart';
import 'package:nts_psc_app/core/utils/background_return_observer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quiz_session_controller.dart';

final quizLifecycleProvider = Provider.autoDispose.family<void, QuizModel>((
  ref,
  quiz,
) {
  final lifecycle = BackgroundReturnObserver(() {
    if (ref.mounted) {
      ref.read(quizSessionProvider(quiz).notifier).refreshDeadline();
    }
  });
  WidgetsBinding.instance.addObserver(lifecycle);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(lifecycle));
});
