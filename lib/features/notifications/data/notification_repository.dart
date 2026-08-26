import '../domain/notification_model.dart';

class NotificationRepository {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'NOTIF-001',
      title: 'Leave Request Pending',
      message: 'Your Leave Request REQ-2026-001245 was submitted and assigned to Sarah Jenkins.',
      requestId: 'REQ-2026-001245',
      timestamp: DateTime(2026, 8, 26, 10, 31),
      isRead: false,
    ),
    NotificationModel(
      id: 'NOTIF-002',
      title: 'Expense Request Approved 🎉',
      message: 'Your Expense Request REQ-2026-001244 (\$185.50) has been approved by Sarah Jenkins.',
      requestId: 'REQ-2026-001244',
      timestamp: DateTime(2026, 8, 21, 09, 45),
      isRead: false,
    ),
    NotificationModel(
      id: 'NOTIF-003',
      title: 'IT Support Ticket Updated',
      message: 'IT Helpdesk Marcus Vance added a note to ticket REQ-2026-001240.',
      requestId: 'REQ-2026-001240',
      timestamp: DateTime(2026, 8, 16, 16, 10),
      isRead: true,
    ),
    NotificationModel(
      id: 'NOTIF-004',
      title: 'Work From Home Approved',
      message: 'Your WFH request REQ-2026-001235 was approved for Aug 10 - Aug 12.',
      requestId: 'REQ-2026-001235',
      timestamp: DateTime(2026, 8, 08, 10, 15),
      isRead: true,
    ),
  ];

  Future<List<NotificationModel>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_notifications);
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
  }
}
