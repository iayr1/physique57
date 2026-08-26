import 'approval_step_model.dart';
import 'request_category_model.dart';
import 'request_status.dart';

class RequestModel {
  final String requestId;
  final String employeeId;
  final String employeeName;
  final String employeeEmail;
  final String department;
  final String managerEmail;
  final RequestType requestType;
  final Map<String, dynamic> requestData;
  final List<String> attachments;
  final RequestStatus status;
  final DateTime submittedAt;
  final DateTime? approvedAt;
  final String? approver;
  final String? rejectionReason;
  final List<ApprovalStepModel> approvalHistory;

  const RequestModel({
    required this.requestId,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.department,
    required this.managerEmail,
    required this.requestType,
    required this.requestData,
    required this.attachments,
    required this.status,
    required this.submittedAt,
    this.approvedAt,
    this.approver,
    this.rejectionReason,
    required this.approvalHistory,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      requestId: json['requestId'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      employeeEmail: json['employeeEmail'] as String,
      department: json['department'] as String,
      managerEmail: json['managerEmail'] as String,
      requestType: RequestType.values.firstWhere(
        (e) => e.name == json['requestType'],
        orElse: () => RequestType.other,
      ),
      requestData: Map<String, dynamic>.from(json['requestData'] ?? {}),
      attachments: List<String>.from(json['attachments'] ?? []),
      status: RequestStatus.fromString(json['status'] ?? 'pendingManagerApproval'),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      approver: json['approver'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      approvalHistory: (json['approvalHistory'] as List<dynamic>?)
              ?.map((e) => ApprovalStepModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeEmail': employeeEmail,
      'department': department,
      'managerEmail': managerEmail,
      'requestType': requestType.name,
      'requestData': requestData,
      'attachments': attachments,
      'status': status.name,
      'submittedAt': submittedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'approver': approver,
      'rejectionReason': rejectionReason,
      'approvalHistory': approvalHistory.map((e) => e.toJson()).toList(),
    };
  }

  RequestModel copyWith({
    RequestStatus? status,
    DateTime? approvedAt,
    String? approver,
    String? rejectionReason,
    List<ApprovalStepModel>? approvalHistory,
  }) {
    return RequestModel(
      requestId: requestId,
      employeeId: employeeId,
      employeeName: employeeName,
      employeeEmail: employeeEmail,
      department: department,
      managerEmail: managerEmail,
      requestType: requestType,
      requestData: requestData,
      attachments: attachments,
      status: status ?? this.status,
      submittedAt: submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approver: approver ?? this.approver,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvalHistory: approvalHistory ?? this.approvalHistory,
    );
  }
}
