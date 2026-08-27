import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/notification_model.dart';
import 'notification_repository.dart';

class FirestoreNotificationRepository implements INotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  String _getUserEmail() {
    return _auth.currentUser?.email ?? '';
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final email = _getUserEmail();
    if (email.isEmpty) return [];

    final snapshot = await _collection
        .where('recipientEmail', isEqualTo: email)
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    final list = snapshot.docs.map((doc) => _fromFirestore(doc.data())).toList();
    
    // Sort descending by timestamp in Dart to prevent index requirements in Firebase console
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _collection.doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead() async {
    final email = _getUserEmail();
    if (email.isEmpty) return;
    final snapshot = await _collection
        .where('recipientEmail', isEqualTo: email)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    final email = _getUserEmail();
    if (email.isEmpty) return;
    final data = _toFirestore(notification, email);
    await _collection.doc(notification.id).set(data);
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
