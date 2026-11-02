import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/notifications/data/local_notification_service.dart';
import 'package:nts_psc_app/features/notifications/data/notification_lifecycle.dart';
import 'package:nts_psc_app/features/notifications/data/notification_repository.dart';
import 'package:nts_psc_app/features/notifications/domain/notification_models.dart';

class LocalReminderController extends AsyncNotifier<Set<String>> {
  @override
  FutureOr<Set<String>> build() async {
    final auth = await ref.watch(authControllerProvider.future);
    if (auth.user == null) return {};
    final reminders = await ref
        .read(notificationRepositoryProvider)
        .listLocalReminders();
    for (final reminder in reminders) {
      await _schedule(reminder);
    }
    return reminders.map((item) => item.key).toSet();
  }

  Future<void> setLiveClassReminder({
    required String sessionId,
    required String courseTitle,
    required String sessionTitle,
    required DateTime startsAt,
    bool enabled = true,
  }) async {
    final key = 'live-class:$sessionId';
    if (!enabled) {
      await ref.read(notificationRepositoryProvider).deleteLocalReminder(key);
      await LocalNotificationService.instance.cancel(key);
      state = AsyncData({...?state.value}..remove(key));
      return;
    }
    final allowed = await ref
        .read(notificationPermissionProvider.notifier)
        .request();
    if (!allowed) {
      throw StateError('Allow notifications to set a reminder.');
    }
    final scheduledAt = startsAt.subtract(const Duration(minutes: 15));
    if (!scheduledAt.isAfter(DateTime.now())) {
      throw StateError('This class starts too soon for a reminder.');
    }
    final reminder = LocalReminderRecord(
      key: key,
      type: AppNotificationType.liveClassReminder,
      resourceId: sessionId,
      scheduledAt: scheduledAt,
      title: 'Live class starts soon',
      body: '$sessionTitle in $courseTitle starts in 15 minutes.',
    );
    await ref.read(notificationRepositoryProvider).saveLocalReminder(reminder);
    await _schedule(reminder);
    state = AsyncData({...?state.value, key});
  }

  Future<void> _schedule(LocalReminderRecord reminder) {
    return LocalNotificationService.instance.schedule(
      scheduleKey: reminder.key,
      date: reminder.scheduledAt,
      title: reminder.title,
      body: reminder.body,
      payload: reminder.payload,
    );
  }
}

final localRemindersProvider =
    AsyncNotifierProvider<LocalReminderController, Set<String>>(
      LocalReminderController.new,
    );
