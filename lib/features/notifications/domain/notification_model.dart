class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String requestId;
  final DateTime timestamp;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.requestId,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      requestId: requestId,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
