import 'package:flutter_riverpod/legacy.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

class QuizDraftEditorState {
  const QuizDraftEditorState({
    required this.category,
    required this.questions,
    this.isSaving = false,
  });

  final String category;
  final List<QuizQuestionModel> questions;
  final bool isSaving;

  QuizDraftEditorState copyWith({
    String? category,
    List<QuizQuestionModel>? questions,
    bool? isSaving,
  }) => QuizDraftEditorState(
    category: category ?? this.category,
    questions: questions ?? this.questions,
    isSaving: isSaving ?? this.isSaving,
  );
}

class QuizDraftEditorController extends StateNotifier<QuizDraftEditorState> {
  QuizDraftEditorController(QuizModel? quiz)
    : super(
        QuizDraftEditorState(
          category: quiz?.category ?? 'Pakistan Affairs',
          questions: List.of(quiz?.questions ?? const []),
        ),
      );

  void setCategory(String category) =>
      state = state.copyWith(category: category);

  void saveQuestion(QuizQuestionModel question, {int? index}) {
    final updated = [...state.questions];
    if (index == null) {
      updated.add(question);
    } else {
      updated[index] = question;
    }
    state = state.copyWith(questions: updated);
  }

  void removeQuestion(int index) {
    final updated = [...state.questions]..removeAt(index);
    state = state.copyWith(questions: updated);
  }

  void setSaving(bool value) => state = state.copyWith(isSaving: value);
}

final quizDraftEditorProvider = StateNotifierProvider.autoDispose
    .family<QuizDraftEditorController, QuizDraftEditorState, QuizModel?>(
      (ref, quiz) => QuizDraftEditorController(quiz),
    );
