import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/notifications/domain/notification_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  String get _userId =>
      _client.auth.currentUser?.id ??
      (throw StateError('Sign in to access notifications.'));

  Future<Map<String, dynamic>> loadPreferences() async {
    return await _client
        .from('user_notification_preferences')
        .select(
          'push_enabled,email_enabled,sms_enabled,course_updates_enabled,'
          'messages_discussions_enabled,exam_results_enabled,promotions_enabled',
        )
        .eq('user_id', _userId)
        .single();
  }

  Future<void> savePreferences(Map<String, bool> values) async {
    await _client
        .from('user_notification_preferences')
        .update(values)
        .eq('user_id', _userId)
        .select('user_id')
        .single();
  }

  Future<List<AppNotificationItem>> list({int limit = 50}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _client
        .from('app_notifications')
        .select(
          'id,event_type,category,title,body,route,resource_id,course_id,'
          'available_at,expires_at,read_at',
        )
        .eq('user_id', _userId)
        .lte('available_at', now)
        .or('expires_at.is.null,expires_at.gt.$now')
        .order('available_at', ascending: false)
        .limit(limit);
    return rows.map(_mapRow).whereType<AppNotificationItem>().toList();
  }

  Future<int> unreadCount() async {
    final now = DateTime.now().toUtc().toIso8601String();
    return _client
        .from('app_notifications')
        .count(CountOption.exact)
        .eq('user_id', _userId)
        .isFilter('read_at', null)
        .lte('available_at', now)
        .or('expires_at.is.null,expires_at.gt.$now');
  }

  Future<void> markRead(String notificationId) async {
    await _client.rpc(
      'mark_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }

  Future<void> markAllRead() async {
    await _client.rpc('mark_all_notifications_read');
  }

  Future<void> touchPushDevice({
    required String token,
    required String platform,
    required String? installationId,
  }) async {
    await _client.rpc(
      'register_push_device',
      params: {
        'p_token': token,
        'p_platform': platform,
        'p_installation_id': installationId,
      },
    );
  }

  Future<List<LocalReminderRecord>> listLocalReminders() async {
    final rows = await _client
        .from('local_notification_reminders')
        .select(
          'reminder_key,event_type,resource_id,course_id,scheduled_at,title,body',
        )
        .eq('user_id', _userId)
        .eq('enabled', true)
        .gt('scheduled_at', DateTime.now().toUtc().toIso8601String());
    return rows.map(LocalReminderRecord.fromRow).toList();
  }

  Future<void> saveLocalReminder(LocalReminderRecord reminder) async {
    await _client.from('local_notification_reminders').upsert({
      'user_id': _userId,
      'reminder_key': reminder.key,
      'event_type': reminder.type.value,
      'resource_id': reminder.resourceId,
      'course_id': reminder.courseId,
      'scheduled_at': reminder.scheduledAt.toUtc().toIso8601String(),
      'title': reminder.title,
      'body': reminder.body,
      'enabled': true,
    }, onConflict: 'user_id,reminder_key');
  }

  Future<void> deleteLocalReminder(String key) async {
    await _client
        .from('local_notification_reminders')
        .delete()
        .eq('user_id', _userId)
        .eq('reminder_key', key);
  }

  AppNotificationItem? _mapRow(Map<String, dynamic> row) {
    final type = AppNotificationType.parse(row['event_type'] as String?);
    AppNotificationCategory? category;
    for (final value in AppNotificationCategory.values) {
      if (value.value == row['category']) category = value;
    }
    if (type == null || category == null) return null;
    return AppNotificationItem(
      id: row['id'] as String,
      type: type,
      category: category,
      title: row['title'] as String,
      body: row['body'] as String,
      route: row['route'] as String,
      resourceId: row['resource_id'] as String?,
      courseId: row['course_id'] as String?,
      createdAt: DateTime.parse(row['available_at'] as String).toLocal(),
      readAt: row['read_at'] == null
          ? null
          : DateTime.parse(row['read_at'] as String).toLocal(),
      expiresAt: row['expires_at'] == null
          ? null
          : DateTime.parse(row['expires_at'] as String).toUtc(),
    );
  }
}

class LocalReminderRecord {
  const LocalReminderRecord({
    required this.key,
    required this.type,
    required this.resourceId,
    required this.scheduledAt,
    required this.title,
    required this.body,
    this.courseId,
  });

  final String key;
  final AppNotificationType type;
  final String resourceId;
  final String? courseId;
  final DateTime scheduledAt;
  final String title;
  final String body;

  factory LocalReminderRecord.fromRow(Map<String, dynamic> row) =>
      LocalReminderRecord(
        key: row['reminder_key'] as String,
        type:
            AppNotificationType.parse(row['event_type'] as String?) ??
            AppNotificationType.liveClassReminder,
        resourceId: row['resource_id'] as String,
        courseId: row['course_id'] as String?,
        scheduledAt: DateTime.parse(row['scheduled_at'] as String).toLocal(),
        title: row['title'] as String,
        body: row['body'] as String,
      );

  AppNotificationPayload get payload => AppNotificationPayload(
    eventId: 'local:$key',
    type: type,
    route: 'live_classes',
    resourceId: resourceId,
    courseId: courseId,
  );
}
