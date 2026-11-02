import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/notifications/data/notification_repository.dart';

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

  factory NotificationsState.fromRow(Map<String, dynamic> row) =>
      NotificationsState(
        pushNotifications: row['push_enabled'] as bool,
        emailNotifications: row['email_enabled'] as bool,
        smsNotifications: row['sms_enabled'] as bool,
        courseUpdates: row['course_updates_enabled'] as bool,
        messagesDiscussions: row['messages_discussions_enabled'] as bool,
        examResults: row['exam_results_enabled'] as bool,
        promotions: row['promotions_enabled'] as bool,
      );

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

  NotificationsState withPushNotifications(bool value) {
    return copyWith(pushNotifications: value);
  }
}

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  @override
  Future<NotificationsState> build() async {
    final userId = ref.watch(authControllerProvider).value?.user?.id;
    if (!AppConfig.isSupabaseEnabled || userId == null) {
      return const NotificationsState();
    }
    final row = await ref
        .read(notificationRepositoryProvider)
        .loadPreferences();
    return NotificationsState.fromRow(row);
  }

  Future<void> _save(
    Map<String, bool> values,
    NotificationsState Function(NotificationsState) update,
  ) async {
    final current = state.value;
    if (current == null) return;
    if (!AppConfig.isSupabaseEnabled) {
      state = AsyncData(update(current));
      return;
    }
    final userId = ref.read(authControllerProvider).value?.user?.id;
    if (userId == null) throw StateError('Sign in to update notifications.');
    state = const AsyncLoading();
    try {
      await ref.read(notificationRepositoryProvider).savePreferences(values);
      if (ref.read(authControllerProvider).value?.user?.id != userId) {
        ref.invalidateSelf();
        return;
      }
      state = AsyncData(update(current));
    } catch (_) {
      if (ref.read(authControllerProvider).value?.user?.id == userId) {
        state = AsyncData(current);
      }
      rethrow;
    }
  }

  Future<void> togglePushNotifications(bool value) => _save({
    'push_enabled': value,
  }, (state) => state.withPushNotifications(value));

  Future<void> toggleEmailNotifications(bool value) => _save({
    'email_enabled': value,
  }, (state) => state.copyWith(emailNotifications: value));

  Future<void> toggleSmsNotifications(bool value) => _save({
    'sms_enabled': value,
  }, (state) => state.copyWith(smsNotifications: value));

  Future<void> toggleCourseUpdates(bool value) => _save({
    'course_updates_enabled': value,
  }, (state) => state.copyWith(courseUpdates: value));

  Future<void> toggleMessagesDiscussions(bool value) => _save({
    'messages_discussions_enabled': value,
  }, (state) => state.copyWith(messagesDiscussions: value));

  Future<void> toggleExamResults(bool value) => _save({
    'exam_results_enabled': value,
  }, (state) => state.copyWith(examResults: value));

  Future<void> togglePromotions(bool value) => _save({
    'promotions_enabled': value,
  }, (state) => state.copyWith(promotions: value));
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsState>(() {
      return NotificationsNotifier();
    });
