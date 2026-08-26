import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/domain/notification_model.dart';
import '../features/requests/domain/request_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repository;

  NotificationNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final list = await _repository.getNotifications();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    await loadNotifications();
  }

  void notifySubmission(RequestModel request) {
    final notif = NotificationModel(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: '${request.requestType.title} Submitted',
      message: 'Your ${request.requestType.title} (${request.requestId}) has been submitted and assigned to ${request.managerEmail}.',
      requestId: request.requestId,
      timestamp: DateTime.now(),
      isRead: false,
    );
    _repository.addNotification(notif);
    loadNotifications();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repo);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final asyncNotifs = ref.watch(notificationProvider);
  return asyncNotifs.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
