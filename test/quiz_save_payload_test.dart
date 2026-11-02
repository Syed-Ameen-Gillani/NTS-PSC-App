import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/repositories/supabase_quiz_repository.dart';

QuizQuestionModel question({
  String text = ' Question ',
  List<String> options = const [' A ', ' B '],
  int answer = 1,
}) => QuizQuestionModel(
  id: 'local-id',
  questionText: text,
  options: options,
  correctOptionIndex: answer,
  explanation: 'Explanation',
);

void main() {
  test('atomic payload preserves question order and answer keys', () {
    final payload = SupabaseQuizRepository.questionPayload([
      question(),
      question(text: 'Second', answer: 0),
    ]);
    expect(payload.first, {
      'question_text': 'Question',
      'options': ['A', 'B'],
      'correct_option_index': 1,
      'explanation': 'Explanation',
    });
    expect(payload.last['question_text'], 'Second');
    expect(payload.last['correct_option_index'], 0);
  });

  test('invalid question payloads are rejected before a network write', () {
    final invalid = [
      <QuizQuestionModel>[],
      [question(text: ' ')],
      [
        question(options: ['A']),
      ],
      [
        question(options: ['A', ' ']),
      ],
      [question(options: List.filled(7, 'A'))],
      [question(answer: -1)],
      [question(), question(answer: 2)],
    ];
    for (final questions in invalid) {
      expect(
        () => SupabaseQuizRepository.questionPayload(questions),
        throwsArgumentError,
      );
    }
  });
}
