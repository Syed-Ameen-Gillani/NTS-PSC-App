import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsState {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool courseUpdates;
  final bool messagesDiscussions;
  final bool examResults;
  final bool promotions;

  const NotificationsState({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.courseUpdates = true,
    this.messagesDiscussions = true,
    this.examResults = true,
    this.promotions = false,
  });

  NotificationsState copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? courseUpdates,
    bool? messagesDiscussions,
    bool? examResults,
    bool? promotions,
  }) {
    return NotificationsState(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      courseUpdates: courseUpdates ?? this.courseUpdates,
      messagesDiscussions: messagesDiscussions ?? this.messagesDiscussions,
      examResults: examResults ?? this.examResults,
      promotions: promotions ?? this.promotions,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    return const NotificationsState();
  }

  void togglePushNotifications(bool value) {
    state = state.copyWith(pushNotifications: value);
  }

  void toggleEmailNotifications(bool value) {
    state = state.copyWith(emailNotifications: value);
  }

  void toggleSmsNotifications(bool value) {
    state = state.copyWith(smsNotifications: value);
  }

  void toggleCourseUpdates(bool value) {
    state = state.copyWith(courseUpdates: value);
  }

  void toggleMessagesDiscussions(bool value) {
    state = state.copyWith(messagesDiscussions: value);
  }

  void toggleExamResults(bool value) {
    state = state.copyWith(examResults: value);
  }

  void togglePromotions(bool value) {
    state = state.copyWith(promotions: value);
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, NotificationsState>(() {
  return NotificationsNotifier();
});
