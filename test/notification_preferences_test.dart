import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/profile/presentation/providers/notifications_provider.dart';

void main() {
  test('notification preferences map every persisted switch', () {
    final preferences = NotificationsState.fromRow({
      'push_enabled': false,
      'email_enabled': true,
      'sms_enabled': false,
      'course_updates_enabled': false,
      'messages_discussions_enabled': true,
      'exam_results_enabled': false,
      'promotions_enabled': true,
    });

    expect(preferences.pushNotifications, false);
    expect(preferences.emailNotifications, true);
    expect(preferences.smsNotifications, false);
    expect(preferences.courseUpdates, false);
    expect(preferences.messagesDiscussions, true);
    expect(preferences.examResults, false);
    expect(preferences.promotions, true);
  });

  test('push master switch preserves notification type preferences', () {
    const preferences = NotificationsState(
      pushNotifications: true,
      courseUpdates: true,
      messagesDiscussions: true,
      examResults: true,
      promotions: true,
    );

    final updated = preferences.withPushNotifications(false);

    expect(updated.pushNotifications, false);
    expect(updated.courseUpdates, preferences.courseUpdates);
    expect(updated.messagesDiscussions, preferences.messagesDiscussions);
    expect(updated.examResults, preferences.examResults);
    expect(updated.promotions, preferences.promotions);
    expect(updated.emailNotifications, preferences.emailNotifications);
    expect(updated.smsNotifications, preferences.smsNotifications);
  });
}
