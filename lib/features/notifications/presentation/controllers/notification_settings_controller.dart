import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/notifications/data/notification_lifecycle.dart';
import 'package:nts_psc_app/features/notifications/data/push_registration.dart';
import 'package:nts_psc_app/features/profile/presentation/providers/notifications_provider.dart';

enum PushPreferenceResult { saved, permissionDenied, settingsRequired, unavailable }

final notificationSettingsControllerProvider = Provider(
  NotificationSettingsController.new,
);

class NotificationSettingsController {
  NotificationSettingsController(this.ref);

  final Ref ref;

  Future<PushPreferenceResult> setPushEnabled(bool enabled) async {
    if (enabled) {
      final permissionController = ref.read(
        notificationPermissionProvider.notifier,
      );
      final status = await permissionController.current();
      if (status == NotificationPermissionStatus.unavailable) {
        return PushPreferenceResult.unavailable;
      }
      if (status == NotificationPermissionStatus.denied) {
        return PushPreferenceResult.settingsRequired;
      }
      if (status == NotificationPermissionStatus.notDetermined) {
        final granted = await permissionController.request();
        if (!granted) return PushPreferenceResult.permissionDenied;
      }
    }
    await ref
        .read(notificationsProvider.notifier)
        .togglePushNotifications(enabled);
    ref.invalidate(pushRegistrationProvider);
    return PushPreferenceResult.saved;
  }
}
