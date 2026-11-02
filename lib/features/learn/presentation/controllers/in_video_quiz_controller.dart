import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/lesson_player_models.dart';
import 'package:nts_psc_app/core/repositories/lesson_player_repository_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_playback_controller.dart';

@immutable
class InVideoQuizState {
  final List<InVideoQuizModel> quizzes;
  final InVideoQuizModel? activeQuiz;
  final int? selectedOptionIndex;
  final QuizSubmissionResult? lastResult;
  final bool isSubmitting;
  final Set<String> completedQuizIds;

  const InVideoQuizState({
    this.quizzes = const [],
    this.activeQuiz,
    this.selectedOptionIndex,
    this.lastResult,
    this.isSubmitting = false,
    this.completedQuizIds = const {},
  });

  bool get isQuizActive => activeQuiz != null;

  InVideoQuizState copyWith({
    List<InVideoQuizModel>? quizzes,
    InVideoQuizModel? activeQuiz,
    bool clearActiveQuiz = false,
    int? selectedOptionIndex,
    bool clearSelectedOption = false,
    QuizSubmissionResult? lastResult,
    bool clearLastResult = false,
    bool? isSubmitting,
    Set<String>? completedQuizIds,
  }) {
    return InVideoQuizState(
      quizzes: quizzes ?? this.quizzes,
      activeQuiz: clearActiveQuiz ? null : (activeQuiz ?? this.activeQuiz),
      selectedOptionIndex: clearSelectedOption
          ? null
          : (selectedOptionIndex ?? this.selectedOptionIndex),
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      completedQuizIds: completedQuizIds ?? this.completedQuizIds,
    );
  }
}

class InVideoQuizNotifier extends Notifier<InVideoQuizState> {
  @override
  InVideoQuizState build() {
    return const InVideoQuizState();
  }

  Future<void> loadQuizzes(String lessonId) async {
    final repo = ref.read(lessonPlayerRepositoryProvider);
    final list = await repo.getInVideoQuizzes(lessonId);
    state = state.copyWith(quizzes: list);
  }

  void triggerQuizById(String quizId) {
    final quiz = state.quizzes.firstWhere(
      (q) => q.id == quizId,
      orElse: () => state.quizzes.isNotEmpty
          ? state.quizzes.first
          : const InVideoQuizModel(
              id: 'fallback',
              lessonId: 'default',
              timestampSeconds: 374,
              timestampDisplay: '06:14',
              topic: 'Executive Authority under AJK Constitution',
              question:
                  'Under the AJK Interim Constitution Act 1974, in whom is the executive authority of the Government of Azad Jammu and Kashmir vested?',
              options: [
                'The Chief Justice of the AJK High Court',
                'The Federal Minister for Kashmir Affairs',
                'The President, exercised directly or through the Prime Minister',
                'The Speaker of the Legislative Assembly',
              ],
              correctOptionIndex: 2,
              explanation:
                  'Under Section 12 of the AJK Interim Constitution Act 1974, executive authority vests in the President and is exercised by him directly or through the Prime Minister and the Council of Ministers.',
              hint:
                  'Review Section 12 regarding the constitutional head and executive exercise.',
            ),
    );

    state = state.copyWith(
      activeQuiz: quiz,
      clearSelectedOption: true,
      clearLastResult: true,
    );
  }

  void selectOption(int index) {
    if (state.lastResult != null && state.lastResult!.isCorrect) {
      // Already correct, cannot change
      return;
    }
    state = state.copyWith(selectedOptionIndex: index);
  }

  Future<QuizSubmissionResult?> submitAnswer() async {
    final quiz = state.activeQuiz;
    final selectedIdx = state.selectedOptionIndex;
    if (quiz == null || selectedIdx == null) return null;

    state = state.copyWith(isSubmitting: true);

    final repo = ref.read(lessonPlayerRepositoryProvider);
    final result = await repo.submitInVideoQuiz(
      quizId: quiz.id,
      selectedOptionIndex: selectedIdx,
    );

    final newCompleted = Set<String>.from(state.completedQuizIds);
    if (result.isCorrect) {
      newCompleted.add(quiz.id);
      ref
          .read(lessonPlaybackControllerProvider.notifier)
          .markCheckpointCompleted(quiz.timestampSeconds);
    }

    state = state.copyWith(
      isSubmitting: false,
      lastResult: result,
      completedQuizIds: newCompleted,
    );

    return result;
  }

  void rewindAndRewatch() {
    // Coursera edge-case pedagogical pattern:
    // Rewind 15 seconds so learner re-absorbs concept, dismiss quiz, resume video.
    final quiz = state.activeQuiz;
    dismissQuiz();
    if (quiz != null) {
      final rewindTarget = (quiz.timestampSeconds - 15).clamp(
        0,
        quiz.timestampSeconds,
      );
      ref
          .read(lessonPlaybackControllerProvider.notifier)
          .seekToSeconds(rewindTarget, allowSkipGuard: false);
      ref.read(lessonPlaybackControllerProvider.notifier).play();
    }
  }

  void resumeVideo() {
    dismissQuiz();
    ref.read(lessonPlaybackControllerProvider.notifier).play();
  }

  void dismissQuiz() {
    ref.read(lessonPlaybackControllerProvider.notifier).clearQuizTrigger();
    state = state.copyWith(
      clearActiveQuiz: true,
      clearSelectedOption: true,
      clearLastResult: true,
    );
  }
}

final inVideoQuizControllerProvider =
    NotifierProvider<InVideoQuizNotifier, InVideoQuizState>(
      InVideoQuizNotifier.new,
    );
