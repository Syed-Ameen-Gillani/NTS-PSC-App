import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/notifications/data/notification_lifecycle.dart';
import 'package:nts_psc_app/features/notifications/data/push_registration.dart';
import 'package:nts_psc_app/features/profile/presentation/providers/notifications_provider.dart';

/// Requests the system prompt once when an eligible signed-in user reaches Home.
final homeNotificationPermissionPromptProvider = Provider(
  HomeNotificationPermissionController.new,
);

class HomeNotificationPermissionController {
  HomeNotificationPermissionController(this.ref);

  final Ref ref;
  bool _attempted = false;

  Future<void> requestOnHomeArrival() async {
    if (_attempted || !pushEnabled) return;
    _attempted = true;

    final auth = await ref.read(authControllerProvider.future);
    if (auth.user == null) return;

    final preferences = await ref.read(notificationsProvider.future);
    if (!preferences.pushNotifications) return;

    final permissionController = ref.read(
      notificationPermissionProvider.notifier,
    );
    final status = await permissionController.current();
    if (status != NotificationPermissionStatus.notDetermined) return;

    final granted = await permissionController.request();
    if (granted && ref.mounted) {
      ref.invalidate(pushRegistrationProvider);
    }
  }
}
