import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/auth/data/auth_integrations.dart';
import 'package:nts_psc_app/features/live_classes/data/live_session_repository.dart';

void main() {
  test(
    'meeting links allow HTTPS and reject credentials and unsafe schemes',
    () {
      expect(
        LiveSessionRepository.validMeetingUrl(
          'https://meet.google.com/abc-defg-hij',
        ),
        isTrue,
      );
      expect(
        LiveSessionRepository.validMeetingUrl(
          'https://example.zoom.us/j/123?pwd=test',
        ),
        isTrue,
      );
      for (final value in [
        'http://meet.google.com/a',
        'javascript:alert(1)',
        'https://user:pass@evil.com',
        'https://example.com/a b',
        'not-a-link',
      ]) {
        expect(
          LiveSessionRepository.validMeetingUrl(value),
          isFalse,
          reason: value,
        );
      }
    },
  );
  test('Apple and recovery fail closed when they are not configured', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
    );
    addTearDown(client.dispose);
    final repository = AuthIntegrations(client);
    expect(googleAuthEnabled, isTrue);
    await expectLater(repository.signIn(OAuthProvider.apple), throwsStateError);
    await expectLater(
      repository.updatePassword('long-password'),
      throwsStateError,
    );
  });
}
