import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:nts_psc_app/features/notifications/domain/notification_models.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const learningUpdatesChannelId = 'learning_updates';
const learningRemindersChannelId = 'learning_reminders';
const quietUpdatesChannelId = 'quiet_updates';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  LocalNotificationService.pendingBackgroundPayload = response.payload;
}

class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();
  static String? pendingBackgroundPayload;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _nativeChannel = MethodChannel('com.ntspsc.app/notifications');
  void Function(AppNotificationPayload payload)? onTap;
  bool Function(AppNotificationPayload payload)? shouldPresent;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        learningUpdatesChannelId,
        'Learning updates',
        description: 'Courses, assignments, quizzes and class updates',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        learningRemindersChannelId,
        'Learning reminders',
        description: 'Reminders you choose for classes and study plans',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        quietUpdatesChannelId,
        'Offers and quiet updates',
        description: 'Optional announcements and promotions',
        importance: Importance.defaultImportance,
      ),
    );
    _initialized = true;
  }

  Future<bool> requestAndroidPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> showForeground({
    required String title,
    required String body,
    required AppNotificationPayload payload,
  }) async {
    await initialize();
    await _plugin.show(
      _stableId(payload.eventId),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelFor(payload.type),
          _channelNameFor(payload.type),
          importance: Importance.high,
          priority: Priority.high,
          tag: payload.eventId,
          groupKey: _groupFor(payload.type),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(payload.toMap()),
    );
  }

  Future<void> schedule({
    required String scheduleKey,
    required DateTime date,
    required String title,
    required String body,
    required AppNotificationPayload payload,
  }) async {
    await initialize();
    if (!date.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      _stableId(scheduleKey),
      title,
      body,
      tz.TZDateTime.from(date, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          learningRemindersChannelId,
          'Learning reminders',
          channelDescription:
              'Reminders you choose for classes and study plans',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode(payload.toMap()),
    );
  }

  Future<void> cancel(String scheduleKey) async {
    await initialize();
    await _plugin.cancel(_stableId(scheduleKey));
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<void> updateBadge(int count) async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _nativeChannel.invokeMethod<void>('setBadgeCount', {
        'count': count,
      });
    }
  }

  Future<AppNotificationPayload?> launchPayload() async {
    await initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    final payload = details?.didNotificationLaunchApp == true
        ? details?.notificationResponse?.payload
        : pendingBackgroundPayload;
    pendingBackgroundPayload = null;
    return _decode(payload);
  }

  void _handleResponse(NotificationResponse response) {
    final payload = _decode(response.payload);
    if (payload != null) onTap?.call(payload);
  }

  AppNotificationPayload? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? AppNotificationPayload.tryParse(decoded)
          : null;
    } catch (_) {
      return null;
    }
  }

  String _channelFor(AppNotificationType type) =>
      type == AppNotificationType.promotion
      ? quietUpdatesChannelId
      : learningUpdatesChannelId;

  String _channelNameFor(AppNotificationType type) =>
      type == AppNotificationType.promotion
      ? 'Offers and quiet updates'
      : 'Learning updates';

  String _groupFor(AppNotificationType type) => switch (type) {
    AppNotificationType.liveClassScheduled ||
    AppNotificationType.liveClassUpdated ||
    AppNotificationType.liveClassCancelled ||
    AppNotificationType.liveClassReminder => 'live_classes',
    AppNotificationType.assignmentPublished ||
    AppNotificationType.assignmentDueReminder ||
    AppNotificationType.assignmentSubmitted ||
    AppNotificationType.assignmentReviewed => 'assignments',
    AppNotificationType.quizPublished => 'quizzes',
    AppNotificationType.discussionReply ||
    AppNotificationType.directFeedback ||
    AppNotificationType.studyNudge => 'messages',
    _ => 'course_updates',
  };

  int _stableId(String value) {
    var hash = 0x811c9dc5;
    for (final code in value.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
