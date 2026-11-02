enum AppNotificationCategory {
  courseUpdates('course_updates'),
  messagesDiscussions('messages_discussions'),
  examResults('exam_results'),
  promotions('promotions');

  const AppNotificationCategory(this.value);
  final String value;
}

enum AppNotificationType {
  liveClassScheduled('live_class_scheduled'),
  liveClassUpdated('live_class_updated'),
  liveClassCancelled('live_class_cancelled'),
  liveClassReminder('live_class_reminder'),
  assignmentPublished('assignment_published'),
  assignmentDueReminder('assignment_due_reminder'),
  assignmentSubmitted('assignment_submitted'),
  assignmentReviewed('assignment_reviewed'),
  quizPublished('quiz_published'),
  coursePublished('course_published'),
  lessonPublished('lesson_published'),
  announcement('announcement'),
  discussionReply('discussion_reply'),
  directFeedback('direct_feedback'),
  studyNudge('study_nudge'),
  promotion('promotion');

  const AppNotificationType(this.value);
  final String value;

  static AppNotificationType? parse(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class AppNotificationPayload {
  const AppNotificationPayload({
    required this.eventId,
    required this.type,
    required this.route,
    this.resourceId,
    this.courseId,
    this.expiresAt,
    this.version = 1,
  });

  final String eventId;
  final AppNotificationType type;
  final String route;
  final String? resourceId;
  final String? courseId;
  final DateTime? expiresAt;
  final int version;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now().toUtc());

  Map<String, String> toMap() => {
    'event_id': eventId,
    'type': type.value,
    'route': route,
    'payload_version': '$version',
    if (resourceId != null) 'resource_id': resourceId!,
    if (courseId != null) 'course_id': courseId!,
    if (expiresAt != null) 'expires_at': expiresAt!.toUtc().toIso8601String(),
  };

  static AppNotificationPayload? tryParse(Map<String, dynamic> data) {
    final eventId = data['event_id']?.toString();
    final type = AppNotificationType.parse(data['type']?.toString());
    final route = data['route']?.toString();
    final version = int.tryParse(data['payload_version']?.toString() ?? '1');
    if (eventId == null ||
        eventId.isEmpty ||
        type == null ||
        route == null ||
        route.isEmpty ||
        version != 1) {
      return null;
    }
    final expiresAt = DateTime.tryParse(data['expires_at']?.toString() ?? '');
    return AppNotificationPayload(
      eventId: eventId,
      type: type,
      route: route,
      resourceId: _nullableText(data['resource_id']),
      courseId: _nullableText(data['course_id']),
      expiresAt: expiresAt,
      version: version!,
    );
  }

  static String? _nullableText(Object? value) {
    final text = value?.toString();
    return text == null || text.isEmpty ? null : text;
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.route,
    required this.createdAt,
    this.resourceId,
    this.courseId,
    this.readAt,
    this.expiresAt,
  });

  final String id;
  final AppNotificationType type;
  final AppNotificationCategory category;
  final String title;
  final String body;
  final String route;
  final String? resourceId;
  final String? courseId;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  bool get isRead => readAt != null;

  AppNotificationPayload get payload => AppNotificationPayload(
    eventId: id,
    type: type,
    route: route,
    resourceId: resourceId,
    courseId: courseId,
    expiresAt: expiresAt,
  );

  AppNotificationItem copyWith({DateTime? readAt}) => AppNotificationItem(
    id: id,
    type: type,
    category: category,
    title: title,
    body: body,
    route: route,
    resourceId: resourceId,
    courseId: courseId,
    createdAt: createdAt,
    readAt: readAt ?? this.readAt,
    expiresAt: expiresAt,
  );
}
