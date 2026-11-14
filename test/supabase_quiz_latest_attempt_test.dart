import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/repositories/supabase_quiz_repository.dart';

void main() {
  test('latest quiz attempt is selected regardless of response order', () {
    final attempts = [
      {
        'id': 'new-q1',
        'quiz_id': 'q1',
        'score': 2,
        'total_questions': 2,
        'submitted_at': '2026-11-03T11:52:48.386812+00:00',
      },
      {
        'id': 'q2-only',
        'quiz_id': 'q2',
        'score': 1,
        'total_questions': 3,
        'submitted_at': '2026-11-02T10:00:00+00:00',
      },
      {
        'id': 'old-q1',
        'quiz_id': 'q1',
        'score': 1,
        'total_questions': 2,
        'submitted_at': '2026-10-28T13:24:48.820423+00:00',
      },
    ];

    final latest = SupabaseQuizRepository.latestAttemptsByQuiz(attempts);

    expect(latest['q1']?['id'], 'new-q1');
    expect(latest['q1']?['score'], 2);
    expect(latest['q2']?['id'], 'q2-only');
  });
}
