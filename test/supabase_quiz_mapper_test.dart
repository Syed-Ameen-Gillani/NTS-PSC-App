import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/repositories/supabase_quiz_repository.dart';

void main() {
  test('saved result honors teacher threshold and exact score', () {
    Map<String, dynamic> result(int score, int total, int threshold) => {
      'attempt_id': 'attempt',
      'quiz_id': 'quiz',
      'quiz_title': 'Assessment',
      'score': score,
      'total_questions': total,
      'passing_score': threshold,
      'questions': <Map<String, dynamic>>[],
    };
    expect(
      SupabaseQuizRepository.mapReviewRow(result(7, 10, 80)).isPassed,
      isFalse,
    );
    expect(
      SupabaseQuizRepository.mapReviewRow(result(8, 10, 80)).isPassed,
      isTrue,
    );
    expect(
      SupabaseQuizRepository.mapReviewRow(result(2, 3, 67)).isPassed,
      isFalse,
    );
    expect(
      SupabaseQuizRepository.mapReviewRow(result(0, 0, 0)).isPassed,
      isFalse,
    );
  });
  final row = <String, dynamic>{
    'id': 'quiz-1',
    'title': 'Pakistan Affairs',
    'category': 'General',
    'difficulty': 'Medium',
    'duration_minutes': 15,
    'passing_score': 60,
    'is_ai_generated': false,
    'status': 'published',
    'quiz_questions': [
      {
        'id': 'question-2',
        'display_order': 1,
        'question_text': 'Second',
        'options': ['No', 'Yes'],
      },
      {
        'id': 'question-1',
        'display_order': 0,
        'question_text': 'First',
        'options': ['A', 'B'],
      },
    ],
  };

  test('student projection omits answer keys and orders questions', () {
    final quiz = SupabaseQuizRepository.mapQuizRow(row);
    expect(quiz.questions.map((question) => question.id), [
      'question-1',
      'question-2',
    ]);
    expect(quiz.questions.first.correctOptionIndex, -1);
    expect(quiz.questions.first.explanation, isEmpty);
  });

  test('teacher projection includes answer keys', () {
    final quiz = SupabaseQuizRepository.mapQuizRow(
      row,
      keyByQuestion: {
        'question-1': {
          'correct_option_index': 1,
          'explanation': 'B is correct',
        },
      },
    );
    expect(quiz.questions.first.correctOptionIndex, 1);
    expect(quiz.questions.first.explanation, 'B is correct');
  });

  test('student quiz retains its saved attempt ID', () {
    final quiz = SupabaseQuizRepository.mapQuizRow(
      row,
      score: '1/2',
      attemptId: 'attempt-1',
    );
    expect(quiz.score, '1/2');
    expect(quiz.attemptId, 'attempt-1');
  });

  test('saved review restores answers in question order', () {
    final review = SupabaseQuizRepository.mapReviewRow({
      'attempt_id': 'attempt-1',
      'quiz_id': 'quiz-1',
      'quiz_title': 'Pakistan Affairs',
      'score': 1,
      'total_questions': 2,
      'questions': [
        {
          'id': 'question-1',
          'question_text': 'First',
          'options': ['A', 'B'],
          'correct_option_index': 1,
          'explanation': 'B is correct',
          'selected_option_index': 1,
        },
        {
          'id': 'question-2',
          'question_text': 'Second',
          'options': ['No', 'Yes'],
          'correct_option_index': 0,
          'explanation': 'No is correct',
          'selected_option_index': null,
        },
      ],
    });
    expect(review.attemptId, 'attempt-1');
    expect(review.userAnswers, {0: 1});
    expect(review.questions.last.correctOptionIndex, 0);
    expect(review.score, 1);
  });
}
