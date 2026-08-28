import 'package:cloud_firestore/cloud_firestore.dart';
import '../../audit/data/audit_repository.dart';
import '../domain/approval_step_model.dart';
import '../domain/request_category_model.dart';
import '../domain/request_model.dart';
import '../domain/request_status.dart';
import 'request_repository.dart';

class FirestoreRequestRepository implements IRequestRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final AuditRepository _auditRepo = AuditRepository();

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

    // Automated Notification to Manager / Admin
    final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
    final targetEmail = newRequest.managerEmail.isNotEmpty
        ? newRequest.managerEmail
        : 'admin@physique57.com';

    await _firestore.collection('notifications').doc(notifId).set({
      'id': notifId,
      'title': 'New ${newRequest.requestType.title} Request',
      'message':
          '${newRequest.employeeName} submitted a new request: ${newRequest.summaryText}',
      'requestId': newRequest.requestId,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'recipientEmail': targetEmail,
    });

    // Automated Audit Log
    await _auditRepo.logAction(
      action: 'REQUEST_SUBMITTED',
      performedBy: newRequest.employeeEmail,
      targetEmail: targetEmail,
      details: '${newRequest.requestType.title} (${newRequest.requestId})',
    );

    return newRequest;
  }

  /// Automated Approval Engine with Instant Quota Deduction & Notifications
  Future<void> approveRequest(
    String requestId, {
    String adminEmail = 'admin@physique57.com',
    String adminName = 'Administrator',
  }) async {
    final req = await getRequestById(requestId);
    final isLeave = req.requestType == RequestType.leave;

    if (isLeave) {
      final leaveType = req.requestData['leaveType'] as String? ?? 'Annual / Paid Leave';
      int days = 1;
      if (req.requestData['days'] != null) {
        days = int.tryParse(req.requestData['days'].toString()) ?? 1;
      } else if (req.requestData['totalDays'] != null) {
        days = int.tryParse(req.requestData['totalDays'].toString()) ?? 1;
      } else if (req.requestData['numberOfDays'] != null) {
        days = int.tryParse(req.requestData['numberOfDays'].toString()) ?? 1;
      }

      // Automated Leave Balance Deduction in Firestore
      final empDoc = await _firestore.collection('employees').doc(req.employeeEmail).get();
      if (empDoc.exists && empDoc.data() != null) {
        final data = empDoc.data()!;
        final balances = Map<String, dynamic>.from(data['leaveBalances'] ?? {});

        String targetKey = 'Annual / Paid Leave';
        if (leaveType.toLowerCase().contains('casual')) {
          targetKey = 'Casual Leave';
        } else if (leaveType.toLowerCase().contains('sick')) {
          targetKey = 'Sick Leave';
        }

        final current = Map<String, dynamic>.from(balances[targetKey] ?? {'total': 18, 'used': 0, 'remaining': 18});
        final total = current['total'] as int? ?? 18;
        final currentUsed = current['used'] as int? ?? 0;
        final currentRemaining = current['remaining'] as int? ?? (total - currentUsed);

        final newUsed = currentUsed + days;
        final newRemaining = (currentRemaining - days).clamp(0, total);

        balances[targetKey] = {
          'total': total,
          'used': newUsed,
          'remaining': newRemaining,
        };

        await _firestore.collection('employees').doc(req.employeeEmail).update({
          'leaveBalances': balances,
        });
      }
    }

    // Update Request Document Status & History
    final updatedHistory = List<ApprovalStepModel>.from(req.approvalHistory);
    updatedHistory.add(ApprovalStepModel(
      title: 'Approved by $adminName',
      actorName: adminName,
      actorRole: 'Admin',
      timestamp: DateTime.now(),
      isCompleted: true,
      isRejected: false,
    ));

    await _collection.doc(requestId).update({
      'status': RequestStatus.approved.name,
      'approvalHistory': updatedHistory.map((s) => _stepToMap(s)).toList(),
    });

    // Automated Notification to Submitter
    final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
    await _firestore.collection('notifications').doc(notifId).set({
      'id': notifId,
      'title': '✓ Request Approved',
      'message': 'Your ${req.requestType.title} request has been approved by $adminName.',
      'requestId': requestId,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'recipientEmail': req.employeeEmail,
    });

    // Automated Audit Log
    await _auditRepo.logAction(
      action: 'REQUEST_APPROVED',
      performedBy: adminEmail,
      targetEmail: req.employeeEmail,
      details: '${req.requestType.title} ($requestId) approved',
    );
  }

  /// Automated Rejection with Notification & Audit Log
  Future<void> rejectRequest(
    String requestId, {
    required String reason,
    String adminEmail = 'admin@physique57.com',
    String adminName = 'Administrator',
  }) async {
    final req = await getRequestById(requestId);

    final updatedHistory = List<ApprovalStepModel>.from(req.approvalHistory);
    updatedHistory.add(ApprovalStepModel(
      title: 'Rejected by $adminName',
      actorName: adminName,
      actorRole: 'Admin',
      timestamp: DateTime.now(),
      isCompleted: false,
      isRejected: true,
      comment: reason,
    ));

    await _collection.doc(requestId).update({
      'status': RequestStatus.rejected.name,
      'rejectionReason': reason,
      'approvalHistory': updatedHistory.map((s) => _stepToMap(s)).toList(),
    });

    // Automated Notification to Submitter
    final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
    await _firestore.collection('notifications').doc(notifId).set({
      'id': notifId,
      'title': 'Request Rejected',
      'message': 'Your ${req.requestType.title} was rejected: $reason',
      'requestId': requestId,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'recipientEmail': req.employeeEmail,
    });

    // Automated Audit Log
    await _auditRepo.logAction(
      action: 'REQUEST_REJECTED',
      performedBy: adminEmail,
      targetEmail: req.employeeEmail,
      details: '${req.requestType.title} ($requestId) rejected: $reason',
    );
  }

  @override
  Future<bool> cancelRequest(String requestId) async {
    final req = await getRequestById(requestId);
    final wasApproved = req.status == RequestStatus.approved;

    // Automated Refund if previously approved leave
    if (wasApproved && req.requestType == RequestType.leave) {
      final leaveType = req.requestData['leaveType'] as String? ?? 'Annual / Paid Leave';
      int days = 1;
      if (req.requestData['days'] != null) {
        days = int.tryParse(req.requestData['days'].toString()) ?? 1;
      }

      final empDoc = await _firestore.collection('employees').doc(req.employeeEmail).get();
      if (empDoc.exists && empDoc.data() != null) {
        final data = empDoc.data()!;
        final balances = Map<String, dynamic>.from(data['leaveBalances'] ?? {});

        String targetKey = 'Annual / Paid Leave';
        if (leaveType.toLowerCase().contains('casual')) {
          targetKey = 'Casual Leave';
        } else if (leaveType.toLowerCase().contains('sick')) {
          targetKey = 'Sick Leave';
        }

        final current = Map<String, dynamic>.from(balances[targetKey] ?? {});
        final total = current['total'] as int? ?? 18;
        final currentUsed = current['used'] as int? ?? 0;
        final currentRemaining = current['remaining'] as int? ?? (total - currentUsed);

        final newUsed = (currentUsed - days).clamp(0, total);
        final newRemaining = (currentRemaining + days).clamp(0, total);

        balances[targetKey] = {
          'total': total,
          'used': newUsed,
          'remaining': newRemaining,
        };

        await _firestore.collection('employees').doc(req.employeeEmail).update({
          'leaveBalances': balances,
        });
      }
    }

    await _collection.doc(requestId).update({
      'status': RequestStatus.cancelled.name,
    });

    // Automated Audit Log
    await _auditRepo.logAction(
      action: 'REQUEST_CANCELLED',
      performedBy: req.employeeEmail,
      targetEmail: req.managerEmail,
      details: '${req.requestType.title} ($requestId) cancelled & quota refunded if applicable',
    );

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
