import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/notifications/data/firestore_notification_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/domain/notification_model.dart';
import '../features/requests/domain/request_model.dart';
import 'auth_provider.dart';

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return FirestoreNotificationRepository();
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final INotificationRepository _repository;
  final Ref _ref;

  NotificationNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final user = _ref.read(authProvider).value;
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
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
  final authState = ref.watch(authProvider);
  final notifier = NotificationNotifier(repo, ref);
  if (authState.value != null) {
    notifier.loadNotifications();
  }
  return notifier;
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final asyncNotifs = ref.watch(notificationProvider);
  return asyncNotifs.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
