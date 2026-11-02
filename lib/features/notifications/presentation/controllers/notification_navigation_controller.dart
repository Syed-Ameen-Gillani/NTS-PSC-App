import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/notifications/data/notification_lifecycle.dart';
import 'package:nts_psc_app/features/notifications/data/local_notification_service.dart';
import 'package:nts_psc_app/features/notifications/data/notification_repository.dart';
import 'package:nts_psc_app/features/notifications/domain/notification_models.dart';
import 'package:nts_psc_app/features/notifications/presentation/controllers/notification_inbox_controller.dart';

final notificationNavigationProvider = Provider<void>((ref) {
  var navigating = false;
  final local = LocalNotificationService.instance;
  local.shouldPresent = (payload) => !_isCurrentDestination(payload);
  ref.onDispose(() => local.shouldPresent = null);

  Future<void> openPending() async {
    if (navigating) return;
    final payload = ref.read(notificationIntentProvider);
    if (payload == null) return;
    navigating = true;
    try {
      final auth = await ref.read(authControllerProvider.future);
      if (auth.user == null) {
        appRouter.goNamed(AppRoute.login.name);
        return;
      }
      ref.read(notificationIntentProvider.notifier).take();
      if (!payload.eventId.startsWith('local:')) {
        try {
          await ref
              .read(notificationRepositoryProvider)
              .markRead(payload.eventId);
          ref.invalidate(notificationInboxProvider);
        } catch (_) {
          // Navigation remains useful while read-state sync retries on refresh.
        }
      }
      _open(payload, auth.user!.role);
    } finally {
      navigating = false;
    }
  }

  ref.listen(notificationIntentProvider, (_, next) {
    if (next != null) unawaited(openPending());
  }, fireImmediately: true);
  ref.listen(authControllerProvider, (_, next) {
    if (next.value?.user != null) unawaited(openPending());
  });
});

void _open(AppNotificationPayload payload, UserRole role) {
  final resourceId = payload.resourceId;
  switch (payload.type) {
    case AppNotificationType.liveClassScheduled:
    case AppNotificationType.liveClassUpdated:
    case AppNotificationType.liveClassCancelled:
    case AppNotificationType.liveClassReminder:
      appRouter.pushNamed(
        role == UserRole.teacher
            ? AppRoute.teacherLiveClasses.name
            : AppRoute.studentLiveClasses.name,
        queryParameters: {if (resourceId != null) 'sessionId': resourceId},
      );
      return;
    case AppNotificationType.assignmentPublished:
    case AppNotificationType.assignmentDueReminder:
    case AppNotificationType.assignmentReviewed:
      if (resourceId == null) return _openInbox();
      appRouter.pushNamed(
        AppRoute.studentAssignment.name,
        queryParameters: {'assignmentId': resourceId},
      );
      return;
    case AppNotificationType.assignmentSubmitted:
      if (resourceId == null) return _openInbox();
      appRouter.pushNamed(
        AppRoute.teacherReviewAssignment.name,
        queryParameters: {'assignmentId': resourceId},
      );
      return;
    case AppNotificationType.quizPublished:
      if (resourceId == null) return _openInbox();
      appRouter.pushNamed(
        AppRoute.activeQuiz.name,
        queryParameters: {'quizId': resourceId},
      );
      return;
    case AppNotificationType.coursePublished:
    case AppNotificationType.announcement:
      final courseId = payload.courseId ?? resourceId;
      if (courseId == null) return _openInbox();
      appRouter.pushNamed(
        AppRoute.courseDetail.name,
        queryParameters: {'courseId': courseId},
      );
      return;
    case AppNotificationType.lessonPublished:
      if (payload.courseId == null || resourceId == null) return _openInbox();
      appRouter.pushNamed(
        AppRoute.lessonPlayer.name,
        queryParameters: {
          'courseId': payload.courseId!,
          'lessonId': resourceId,
        },
      );
      return;
    case AppNotificationType.discussionReply:
    case AppNotificationType.directFeedback:
    case AppNotificationType.studyNudge:
      if (role == UserRole.teacher) {
        appRouter.pushNamed(AppRoute.teacherDoubts.name);
      } else if (payload.courseId != null) {
        appRouter.pushNamed(
          AppRoute.courseDetail.name,
          queryParameters: {'courseId': payload.courseId!},
        );
      } else {
        _openInbox();
      }
      return;
    case AppNotificationType.promotion:
      _openInbox();
      return;
  }
}

void _openInbox() => appRouter.pushNamed(AppRoute.notificationInbox.name);

bool _isCurrentDestination(AppNotificationPayload payload) {
  final uri = appRouter.routerDelegate.currentConfiguration.uri;
  if (uri.path == AppRoute.notificationInbox.path) return true;
  if ({
        AppNotificationType.liveClassScheduled,
        AppNotificationType.liveClassUpdated,
        AppNotificationType.liveClassCancelled,
        AppNotificationType.liveClassReminder,
      }.contains(payload.type) &&
      (uri.path == AppRoute.studentLiveClasses.path ||
          uri.path == AppRoute.teacherLiveClasses.path)) {
    return true;
  }
  final expectedPath = switch (payload.type) {
    AppNotificationType.liveClassScheduled ||
    AppNotificationType.liveClassUpdated ||
    AppNotificationType.liveClassCancelled ||
    AppNotificationType.liveClassReminder => AppRoute.studentLiveClasses.path,
    AppNotificationType.assignmentPublished ||
    AppNotificationType.assignmentDueReminder ||
    AppNotificationType.assignmentReviewed => AppRoute.studentAssignment.path,
    AppNotificationType.assignmentSubmitted =>
      AppRoute.teacherReviewAssignment.path,
    AppNotificationType.quizPublished => AppRoute.activeQuiz.path,
    AppNotificationType.lessonPublished => AppRoute.lessonPlayer.path,
    AppNotificationType.coursePublished ||
    AppNotificationType.announcement => AppRoute.courseDetail.path,
    AppNotificationType.discussionReply ||
    AppNotificationType.directFeedback ||
    AppNotificationType.studyNudge ||
    AppNotificationType.promotion => null,
  };
  if (expectedPath == null || uri.path != expectedPath) return false;
  final currentResource =
      uri.queryParameters['assignmentId'] ??
      uri.queryParameters['quizId'] ??
      uri.queryParameters['lessonId'] ??
      uri.queryParameters['courseId'] ??
      uri.queryParameters['sessionId'];
  return currentResource == null || currentResource == payload.resourceId;
}
