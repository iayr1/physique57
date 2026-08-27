import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/audit_log_model.dart';

class AuditRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('audit_logs');

  Stream<List<AuditLogModel>> getAuditLogsStream() {
    return _collection.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return AuditLogModel.fromJson({'id': doc.id, ...data});
      }).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<void> logAction({
    required String action,
    required String performedBy,
    required String targetEmail,
    required String details,
  }) async {
    final id = 'AUD-${DateTime.now().millisecondsSinceEpoch}';
    final log = AuditLogModel(
      id: id,
      action: action,
      performedBy: performedBy,
      targetEmail: targetEmail,
      details: details,
      timestamp: DateTime.now(),
    );

    try {
      await _collection.doc(id).set(log.toJson());
    } catch (_) {}
  }
}
