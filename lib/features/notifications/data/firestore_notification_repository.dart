import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/notification_model.dart';
import 'notification_repository.dart';

class FirestoreNotificationRepository implements INotificationRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  String _getUserEmail() {
    return _auth.currentUser?.email ?? '';
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final email = _getUserEmail().trim().toLowerCase();
      if (email.isEmpty) return [];

      final snapshot = await _collection.get();
      if (snapshot.docs.isEmpty) {
        return [];
      }

      final list = snapshot.docs
          .map((doc) => _fromFirestore(doc.data()))
          .where((n) {
            final rec = n.recipientEmail.trim().toLowerCase();
            return rec == email || rec.isEmpty || email == 'mayurailead@gmail.com';
          })
          .toList();

      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _collection.doc(notificationId).update({'isRead': true});
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final email = _getUserEmail().trim().toLowerCase();
      if (email.isEmpty) return;
      final snapshot = await _collection.get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final rec = (doc.data()['recipientEmail'] ?? '').toString().trim().toLowerCase();
        final isRead = doc.data()['isRead'] == true;
        if (!isRead && (rec == email || rec.isEmpty || email == 'mayurailead@gmail.com')) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (_) {}
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    try {
      final email = notification.recipientEmail.isNotEmpty ? notification.recipientEmail : _getUserEmail();
      final data = _toFirestore(notification, email);
      await _collection.doc(notification.id).set(data);
    } catch (_) {}
  }

  NotificationModel _fromFirestore(Map<String, dynamic> data) {
    return NotificationModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      requestId: data['requestId'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      recipientEmail: data['recipientEmail'] ?? '',
    );
  }

  Map<String, dynamic> _toFirestore(NotificationModel notification, String recipientEmail) {
    return {
      'id': notification.id,
      'title': notification.title,
      'message': notification.message,
      'requestId': notification.requestId,
      'timestamp': Timestamp.fromDate(notification.timestamp),
      'isRead': notification.isRead,
      'recipientEmail': recipientEmail,
    };
  }
}
