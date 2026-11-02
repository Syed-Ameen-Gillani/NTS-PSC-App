import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nts_psc_app/features/notifications/data/local_notification_service.dart';
import 'package:nts_psc_app/features/notifications/domain/notification_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android displays every notification type', (tester) async {
    await LocalNotificationService.instance.initialize();
    for (final type in AppNotificationType.values) {
      await LocalNotificationService.instance.showForeground(
        title: 'Notification test: ${type.value}',
        body: 'Pixel 5 notification delivery is working.',
        payload: AppNotificationPayload(
          eventId: 'local:android-${type.value}',
          type: type,
          route: 'notification_inbox',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  });
}
