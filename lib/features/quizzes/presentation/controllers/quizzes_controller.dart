import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

class QuizzesState {
  final List<QuizModel> aiQuizzes;
  final List<QuizModel> courseQuizzes;

  QuizzesState({
    this.aiQuizzes = const [],
    this.courseQuizzes = const [],
  });
}

class QuizzesController extends AsyncNotifier<QuizzesState> {
  @override
  FutureOr<QuizzesState> build() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    
    return QuizzesState(
      aiQuizzes: [
        QuizModel(
          id: '1',
          title: 'Current Affairs Weekly Challenge',
          category: 'Current Affairs',
          isAiGenerated: true,
          totalQuestions: 15,
          score: null,
        ),
        QuizModel(
          id: '2',
          title: 'English Grammar Weak Areas',
          category: 'English',
          isAiGenerated: true,
          totalQuestions: 20,
          score: '16/20',
        ),
      ],
      courseQuizzes: [
        QuizModel(
          id: '3',
          title: 'Pakistan Studies - Pre-Partition',
          category: 'Pakistan Affairs',
          isAiGenerated: false,
          totalQuestions: 25,
          score: null,
        ),
        QuizModel(
          id: '4',
          title: 'General Science Basics',
          category: 'Everyday Science',
          isAiGenerated: false,
          totalQuestions: 10,
          score: '8/10',
        ),
        QuizModel(
          id: '5',
          title: 'Islamic Studies Mock Test 1',
          category: 'Islamic Studies',
          isAiGenerated: false,
          totalQuestions: 50,
          score: null,
        ),
      ],
    );
  }
}

final quizzesControllerProvider = AsyncNotifierProvider<QuizzesController, QuizzesState>(() {
  return QuizzesController();
});
