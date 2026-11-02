import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const authRedirectUrl = 'com.ntspsc.app://auth-callback/';
const googleAuthEnabled = true;
const appleAuthEnabled = bool.fromEnvironment('APPLE_AUTH_ENABLED');

final authIntegrationsProvider = Provider(
  (ref) => AuthIntegrations(Supabase.instance.client),
);
final authCallbackProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

class AuthIntegrations {
  AuthIntegrations(this.client);
  final SupabaseClient client;
  static bool awaitingOAuth = false;
  static bool recoveringPassword = false;

  Future<void> signIn(OAuthProvider provider) async {
    if ((provider == OAuthProvider.google && !googleAuthEnabled) ||
        (provider == OAuthProvider.apple && !appleAuthEnabled)) {
      throw StateError('This sign-in provider is not configured yet.');
    }
    if (kIsWeb) {
      throw StateError(
        'Configure web callback URLs before enabling web sign-in.',
      );
    }
    awaitingOAuth = true;
    try {
      final launched = await client.auth.signInWithOAuth(
        provider,
        redirectTo: authRedirectUrl,
      );
      if (!launched) throw StateError('Could not open the sign-in page.');
    } catch (_) {
      awaitingOAuth = false;
      rethrow;
    }
  }

  Future<void> updatePassword(String password) async {
    if (!recoveringPassword || client.auth.currentSession == null) {
      throw StateError('Open a valid password recovery link first.');
    }
    if (password.length < 8) throw ArgumentError('Use at least 8 characters.');
    await client.auth.updateUser(UserAttributes(password: password));
    recoveringPassword = false;
    await client.auth.signOut();
  }
}
