import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/approval_step_model.dart';
import '../domain/request_category_model.dart';
import '../domain/request_model.dart';
import '../domain/request_status.dart';
import 'mock_request_repository.dart';
import 'request_repository.dart';

class FirestoreRequestRepository implements IRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MockRequestRepository _fallbackMock = MockRequestRepository();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('requests');

  @override
  Future<List<RequestModel>> getEmployeeRequests(String employeeEmail) async {
    try {
      final snapshot = await _collection
          .where('employeeEmail', isEqualTo: employeeEmail)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.docs.isEmpty) {
        // Return initial mock requests if Firestore collection is empty
        return _fallbackMock.getEmployeeRequests(employeeEmail);
      }

      return snapshot.docs.map((doc) => _fromFirestore(doc.data())).toList();
    } catch (_) {
      // Fallback to local memory mock repository if offline or uninitialized
      return _fallbackMock.getEmployeeRequests(employeeEmail);
    }
  }

  @override
  Future<RequestModel> getRequestById(String requestId) async {
    try {
      final doc = await _collection.doc(requestId).get();
      if (doc.exists && doc.data() != null) {
        return _fromFirestore(doc.data()!);
      }
    } catch (_) {}
    return _fallbackMock.getRequestById(requestId);
  }

  @override
  Future<RequestModel> submitRequest(RequestModel newRequest) async {
    try {
      final data = _toFirestore(newRequest);
      await _collection.doc(newRequest.requestId).set(data);
    } catch (_) {}
    return _fallbackMock.submitRequest(newRequest);
  }

  @override
  Future<bool> cancelRequest(String requestId) async {
    try {
      await _collection.doc(requestId).update({
        'status': RequestStatus.cancelled.name,
      });
    } catch (_) {}
    return _fallbackMock.cancelRequest(requestId);
  }

  RequestModel _fromFirestore(Map<String, dynamic> data) {
    return RequestModel(
      requestId: data['requestId'] ?? '',
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      employeeEmail: data['employeeEmail'] ?? '',
      department: data['department'] ?? '',
      managerEmail: data['managerEmail'] ?? '',
      requestType: RequestType.values.firstWhere(
        (e) => e.name == data['requestType'] || e.title == data['requestType'],
        orElse: () => RequestType.other,
      ),
      requestData: Map<String, dynamic>.from(data['requestData'] ?? {}),
      attachments: List<String>.from(data['attachments'] ?? []),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.pendingManagerApproval,
      ),
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
