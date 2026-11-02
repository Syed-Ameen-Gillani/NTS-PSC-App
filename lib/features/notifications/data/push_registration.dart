import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/notifications/data/notification_lifecycle.dart';
import 'package:nts_psc_app/features/notifications/data/notification_repository.dart';
import 'package:nts_psc_app/features/profile/presentation/providers/notifications_provider.dart';
import 'package:nts_psc_app/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final pushRegistrationProvider = FutureProvider<void>((ref) async {
  if (!pushEnabled ||
      !AppConfig.isSupabaseEnabled ||
      kIsWeb ||
      ![
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform)) {
    return;
  }
  final user = ref.watch(authControllerProvider).value?.user;
  final preferences = ref.watch(notificationsProvider).value;
  if (user == null || preferences == null) return;
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  final messaging = FirebaseMessaging.instance;
  if (!preferences.pushNotifications) {
    await PushRegistration.unregister();
    return;
  }
  final permission = await messaging.getNotificationSettings();
  if (![
    AuthorizationStatus.authorized,
    AuthorizationStatus.provisional,
  ].contains(permission.authorizationStatus)) {
    return;
  }
  if (defaultTargetPlatform == TargetPlatform.iOS &&
      await messaging.getAPNSToken() == null) {
    return;
  }
  await messaging.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );
  Future<void> register(String token) async {
    if (!ref.mounted ||
        Supabase.instance.client.auth.currentUser?.id != user.id) {
      return;
    }
    await ref
        .read(notificationRepositoryProvider)
        .touchPushDevice(
          token: token,
          platform: defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
          installationId: null,
        );
  }

  final token = await messaging.getToken();
  if (token != null) await register(token);
  if (!ref.mounted) return;
  final subscription = messaging.onTokenRefresh.listen((token) async {
    try {
      await register(token);
    } catch (_) {
      if (ref.mounted) ref.invalidateSelf();
    }
  });
  ref.onDispose(subscription.cancel);
});

class PushRegistration {
  static Future<void> unregister() async {
    if (!pushEnabled || Firebase.apps.isEmpty) return;
    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();
    try {
      if (token != null && Supabase.instance.client.auth.currentUser != null) {
        await Supabase.instance.client
            .from('push_devices')
            .delete()
            .eq('token', token);
      }
    } finally {
      // Attempt FCM revocation too; offline failures still require later cleanup.
      await messaging.deleteToken();
    }
  }
}
