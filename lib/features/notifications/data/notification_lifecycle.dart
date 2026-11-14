import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/utils/background_return_observer.dart';
import 'package:nts_psc_app/core/utils/lifecycle_diagnostics.dart';
import 'package:nts_psc_app/features/notifications/data/local_notification_service.dart';
import 'package:nts_psc_app/features/notifications/domain/notification_models.dart';
import 'package:nts_psc_app/features/notifications/presentation/controllers/local_reminder_controller.dart';
import 'package:nts_psc_app/features/notifications/presentation/controllers/notification_inbox_controller.dart';
import 'package:nts_psc_app/firebase_options.dart';

const pushEnabled = bool.fromEnvironment('PUSH_ENABLED', defaultValue: true);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> initializeNotificationBootstrap() async {
  if (!pushEnabled ||
      kIsWeb ||
      !{
        TargetPlatform.android,
        TargetPlatform.iOS,
      }.contains(defaultTargetPlatform)) {
    return;
  }
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await LocalNotificationService.instance.initialize();
}

enum NotificationPermissionStatus {
  notDetermined,
  provisional,
  authorized,
  denied,
  unavailable,
}

final notificationPermissionProvider =
    AsyncNotifierProvider<
      NotificationPermissionController,
      NotificationPermissionStatus
    >(NotificationPermissionController.new);

class NotificationPermissionController
    extends AsyncNotifier<NotificationPermissionStatus> {
  @override
  Future<NotificationPermissionStatus> build() => current();

  Future<NotificationPermissionStatus> current() async {
    if (!pushEnabled || Firebase.apps.isEmpty) {
      return NotificationPermissionStatus.unavailable;
    }
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return _map(settings.authorizationStatus);
  }

  Future<bool> request({bool provisional = false}) async {
    if (!pushEnabled || Firebase.apps.isEmpty) return false;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: defaultTargetPlatform == TargetPlatform.iOS && provisional,
    );
    final mapped = _map(settings.authorizationStatus);
    state = AsyncData(mapped);
    return mapped == NotificationPermissionStatus.authorized ||
        mapped == NotificationPermissionStatus.provisional;
  }

  Future<void> refresh() async {
    final permission = await current();
    if (ref.mounted) state = AsyncData(permission);
  }

  Future<void> openDeviceSettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);

  NotificationPermissionStatus _map(
    AuthorizationStatus status,
  ) => switch (status) {
    AuthorizationStatus.authorized => NotificationPermissionStatus.authorized,
    AuthorizationStatus.provisional => NotificationPermissionStatus.provisional,
    AuthorizationStatus.denied => NotificationPermissionStatus.denied,
    AuthorizationStatus.deniedPermanently =>
      NotificationPermissionStatus.denied,
    AuthorizationStatus.notDetermined =>
      NotificationPermissionStatus.notDetermined,
  };
}

class NotificationIntentController extends Notifier<AppNotificationPayload?> {
  @override
  AppNotificationPayload? build() => null;

  void receive(AppNotificationPayload payload) {
    if (!payload.isExpired) state = payload;
  }

  AppNotificationPayload? take() {
    final value = state;
    state = null;
    return value;
  }
}

final notificationIntentProvider =
    NotifierProvider<NotificationIntentController, AppNotificationPayload?>(
      NotificationIntentController.new,
    );

final notificationLifecycleProvider = FutureProvider<void>((ref) async {
  if (!pushEnabled || Firebase.apps.isEmpty) return;
  final local = LocalNotificationService.instance;
  final observer = BackgroundReturnObserver(() async {
    if (!ref.mounted) return;
    final before = ref.read(notificationPermissionProvider).value;
    try {
      await ref.read(notificationPermissionProvider.notifier).refresh();
      if (!ref.mounted) return;
      final after = ref.read(notificationPermissionProvider).value;
      if (before != after) {
        LifecycleDiagnostics.event('notifications', 'permission-changed');
        ref.invalidate(localRemindersProvider);
      }
    } catch (_) {
      LifecycleDiagnostics.event('notifications', 'permission-check-failed');
    }
  });
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  void receive(AppNotificationPayload payload) {
    if (ref.mounted) {
      ref.read(notificationIntentProvider.notifier).receive(payload);
    }
  }

  local.onTap = receive;
  ref.onDispose(() => local.onTap = null);

  final localLaunch = await local.launchPayload();
  if (!ref.mounted) return;
  if (localLaunch != null) receive(localLaunch);

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (!ref.mounted) return;
  final initialPayload = initialMessage == null
      ? null
      : AppNotificationPayload.tryParse(initialMessage.data);
  if (initialPayload != null) receive(initialPayload);

  final openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
    message,
  ) {
    LifecycleDiagnostics.event('firebase', 'message-opened');
    final payload = AppNotificationPayload.tryParse(message.data);
    if (payload != null) receive(payload);
  });
  ref.onDispose(openedSubscription.cancel);

  final foregroundSubscription = FirebaseMessaging.onMessage.listen((
    message,
  ) async {
    if (!ref.mounted) return;
    LifecycleDiagnostics.event('firebase', 'foreground-message');
    final payload = AppNotificationPayload.tryParse(message.data);
    if (payload == null || payload.isExpired) return;
    ref.invalidate(notificationInboxProvider);
    if (local.shouldPresent?.call(payload) ?? true) {
      await local.showForeground(
        title: message.notification?.title ?? 'NTS/PSC update',
        body: message.notification?.body ?? 'Open the app to view this update.',
        payload: payload,
      );
    }
  });
  ref.onDispose(foregroundSubscription.cancel);
  LifecycleDiagnostics.event('firebase', 'listeners-attached');
  ref.onDispose(
    () => LifecycleDiagnostics.event('firebase', 'listeners-disposed'),
  );
});
