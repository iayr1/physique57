import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/approval_step_model.dart';
import '../domain/request_category_model.dart';
import '../domain/request_model.dart';
import '../domain/request_status.dart';
import 'request_repository.dart';

class FirestoreRequestRepository implements IRequestRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('requests');

  @override
  Future<List<RequestModel>> getEmployeeRequests(String employeeEmail) async {
    try {
      final email = employeeEmail.trim().toLowerCase();
      final snapshot = await _collection.get();
      if (snapshot.docs.isEmpty) {
        return [];
      }

      final list = snapshot.docs
          .map((doc) => _fromFirestore(doc.data()))
          .where((r) => r.employeeEmail.trim().toLowerCase() == email)
          .toList();

      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<RequestModel> getRequestById(String requestId) async {
    final doc = await _collection.doc(requestId).get();
    if (doc.exists && doc.data() != null) {
      return _fromFirestore(doc.data()!);
    }
    throw Exception('Request $requestId not found in Firestore');
  }

  @override
  Future<RequestModel> submitRequest(RequestModel newRequest) async {
    final data = _toFirestore(newRequest);
    await _collection.doc(newRequest.requestId).set(data);
    return newRequest;
  }

  @override
  Future<bool> cancelRequest(String requestId) async {
    await _collection.doc(requestId).update({
      'status': RequestStatus.cancelled.name,
    });
    return true;
  }

  RequestModel _fromFirestore(Map<String, dynamic> data) {
    final rawType = (data['requestType'] ?? '').toString();
    final type = RequestType.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == rawType.toLowerCase() ||
          e.title.toLowerCase() == rawType.toLowerCase() ||
          rawType.toLowerCase().contains(e.name.toLowerCase()),
      orElse: () => RequestType.leave,
    );

    return RequestModel(
      requestId: data['requestId'] ?? '',
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      employeeEmail: data['employeeEmail'] ?? '',
      department: data['department'] ?? '',
      managerEmail: data['managerEmail'] ?? '',
      requestType: type,
      requestData: Map<String, dynamic>.from(data['requestData'] ?? {}),
      attachments: List<String>.from(data['attachments'] ?? []),
      status: RequestStatus.fromString(data['status']?.toString() ?? ''),
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] is Timestamp
              ? (data['submittedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['submittedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      rejectionReason: data['rejectionReason'],
      approvalHistory: (data['approvalHistory'] as List<dynamic>?)
              ?.map((step) => _stepFromMap(step as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> _toFirestore(RequestModel request) {
    return {
      'requestId': request.requestId,
      'employeeId': request.employeeId,
      'employeeName': request.employeeName,
      'employeeEmail': request.employeeEmail,
      'department': request.department,
      'managerEmail': request.managerEmail,
      'requestType': request.requestType.name,
      'requestData': request.requestData,
      'attachments': request.attachments,
      'status': request.status.name,
      'submittedAt': Timestamp.fromDate(request.submittedAt),
      'rejectionReason': request.rejectionReason,
      'approvalHistory': request.approvalHistory.map((s) => _stepToMap(s)).toList(),
    };
  }

  ApprovalStepModel _stepFromMap(Map<String, dynamic> m) {
    return ApprovalStepModel(
      title: m['title'] ?? '',
      actorName: m['actorName'],
      actorRole: m['actorRole'],
      timestamp: m['timestamp'] != null
          ? (m['timestamp'] is Timestamp
              ? (m['timestamp'] as Timestamp).toDate()
              : DateTime.tryParse(m['timestamp'].toString()))
          : null,
      isCompleted: m['isCompleted'] ?? false,
      isRejected: m['isRejected'] ?? false,
      comment: m['comment'],
    );
  }

  Map<String, dynamic> _stepToMap(ApprovalStepModel s) {
    return {
      'title': s.title,
      'actorName': s.actorName,
      'actorRole': s.actorRole,
      'timestamp': s.timestamp != null ? Timestamp.fromDate(s.timestamp!) : null,
      'isCompleted': s.isCompleted,
      'isRejected': s.isRejected,
      'comment': s.comment,
    };
  }
}
