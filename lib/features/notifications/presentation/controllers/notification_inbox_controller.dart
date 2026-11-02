import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/notifications/data/notification_repository.dart';
import 'package:nts_psc_app/features/notifications/data/local_notification_service.dart';
import 'package:nts_psc_app/features/notifications/domain/notification_models.dart';

class NotificationInboxState {
  const NotificationInboxState({this.items = const [], this.totalUnread});

  final List<AppNotificationItem> items;
  final int? totalUnread;
  int get unreadCount =>
      totalUnread ?? items.where((item) => !item.isRead).length;
}

class NotificationInboxController
    extends AsyncNotifier<NotificationInboxState> {
  @override
  FutureOr<NotificationInboxState> build() async {
    final user = await ref.watch(authControllerProvider.future);
    if (user.user == null) return const NotificationInboxState();
    final repository = ref.read(notificationRepositoryProvider);
    final itemsRequest = repository.list();
    final countRequest = repository.unreadCount();
    final items = await itemsRequest;
    final result = NotificationInboxState(
      items: items,
      totalUnread: await countRequest,
    );
    await LocalNotificationService.instance.updateBadge(result.unreadCount);
    return result;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null) return;
    final item = current.items.where((entry) => entry.id == id).firstOrNull;
    if (item == null || item.isRead) return;
    final readAt = DateTime.now();
    state = AsyncData(
      NotificationInboxState(
        totalUnread: (current.unreadCount - 1).clamp(0, 1 << 30),
        items: [
          for (final entry in current.items)
            if (entry.id == id) entry.copyWith(readAt: readAt) else entry,
        ],
      ),
    );
    try {
      await ref.read(notificationRepositoryProvider).markRead(id);
      await LocalNotificationService.instance.updateBadge(
        state.value?.unreadCount ?? 0,
      );
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null || current.unreadCount == 0) return;
    final readAt = DateTime.now();
    state = AsyncData(
      NotificationInboxState(
        totalUnread: 0,
        items: [
          for (final item in current.items) item.copyWith(readAt: readAt),
        ],
      ),
    );
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      await LocalNotificationService.instance.updateBadge(0);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final notificationInboxProvider =
    AsyncNotifierProvider<NotificationInboxController, NotificationInboxState>(
      NotificationInboxController.new,
    );

final notificationUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationInboxProvider).value?.unreadCount ?? 0;
});
