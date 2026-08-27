import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/announcement_model.dart';

class AnnouncementRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('announcements');

  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    return _collection.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return AnnouncementModel.fromJson({'id': doc.id, ...data});
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> createAnnouncement({
    required String title,
    required String message,
    String priority = 'Normal',
    String createdBy = 'Administrator',
    String? actionUrl,
  }) async {
    final id = 'ANN-${DateTime.now().millisecondsSinceEpoch}';
    final announcement = AnnouncementModel(
      id: id,
      title: title,
      message: message,
      priority: priority,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      actionUrl: actionUrl,
    );

    await _collection.doc(id).set(announcement.toJson());

    // Automatically create a notification in notifications collection
    final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
    await _firestore.collection('notifications').doc(notifId).set({
      'id': notifId,
      'title': '📢 $title',
      'message': message,
      'requestId': id,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'recipientEmail': 'all',
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _collection.doc(id).delete();
  }
}
