import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';

void main() {
  test(
    'server lifetime tolerates device date/timezone offsets and expires safely',
    () {
      final ticket = {
        'started_at': '2026-10-27T00:00:00Z',
        'expires_at': '2026-11-03T00:00:00Z',
        '_cached_at': '2030-01-01T10:00:00+05:00',
      };
      expect(
        LearningEvidenceRepository.ticketIsCurrent(
          ticket,
          now: DateTime.parse('2030-01-01T05:05:00Z'),
        ),
        true,
      );
      expect(
        LearningEvidenceRepository.ticketIsCurrent(
          ticket,
          now: DateTime.parse('2030-01-08T05:00:00Z'),
        ),
        false,
      );
      expect(
        LearningEvidenceRepository.ticketIsCurrent(
          ticket,
          now: DateTime.parse('2029-12-31T00:00:00Z'),
        ),
        false,
      );
      expect(LearningEvidenceRepository.ticketIsCurrent({}), false);
    },
  );
}
