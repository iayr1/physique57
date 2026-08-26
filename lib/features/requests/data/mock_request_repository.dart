import '../domain/approval_step_model.dart';
import '../domain/request_category_model.dart';
import '../domain/request_model.dart';
import '../domain/request_status.dart';
import 'request_repository.dart';

class MockRequestRepository implements IRequestRepository {
  final List<RequestModel> _mockDatabase = [
    RequestModel(
      requestId: 'REQ-2026-001245',
      employeeId: 'EMP-8842',
      employeeName: 'Alex Morgan',
      employeeEmail: 'alex.morgan@acmeglobal.com',
      department: 'Engineering & Technology',
      managerEmail: 'sarah.jenkins@acmeglobal.com',
      requestType: RequestType.leave,
      requestData: {
        'leaveType': 'Annual / Paid Leave',
        'startDate': '2026-09-01',
        'endDate': '2026-09-05',
        'numberOfDays': 5,
        'reason': 'Attending annual family reunion and personal vacation.',
      },
      attachments: ['https://example.com/docs/leave_approval_ticket.pdf'],
      status: RequestStatus.pendingManagerApproval,
      submittedAt: DateTime(2026, 8, 26, 10, 30),
      approvalHistory: [
        ApprovalStepModel(
          title: 'Request Submitted',
          actorName: 'Alex Morgan',
          actorRole: 'Employee',
          timestamp: DateTime(2026, 8, 26, 10, 30),
          isCompleted: true,
        ),
        ApprovalStepModel(
          title: 'Pending Manager Approval',
          actorName: 'Sarah Jenkins',
          actorRole: 'Engineering Manager',
          timestamp: DateTime(2026, 8, 26, 10, 31),
          isCompleted: false,
        ),
        const ApprovalStepModel(
          title: 'HR Processing & Record Update',
          actorName: 'HR Service Desk',
          actorRole: 'HR Operations',
          isCompleted: false,
        ),
      ],
    ),
    RequestModel(
      requestId: 'REQ-2026-001244',
      employeeId: 'EMP-8842',
      employeeName: 'Alex Morgan',
      employeeEmail: 'alex.morgan@acmeglobal.com',
      department: 'Engineering & Technology',
      managerEmail: 'sarah.jenkins@acmeglobal.com',
      requestType: RequestType.expense,
      requestData: {
        'category': 'Client Lunch & Hospitality',
        'amount': 185.50,
        'currency': 'USD',
        'expenseDate': '2026-08-20',
        'description': 'Quarterly strategy review meal with AWS Cloud Enterprise architects.',
      },
      attachments: ['receipt_aws_lunch_2026.png'],
      status: RequestStatus.approved,
      submittedAt: DateTime(2026, 8, 20, 14, 15),
      approvedAt: DateTime(2026, 8, 21, 09, 45),
      approver: 'Sarah Jenkins',
      approvalHistory: [
        ApprovalStepModel(
          title: 'Request Submitted',
          actorName: 'Alex Morgan',
          actorRole: 'Employee',
          timestamp: DateTime(2026, 8, 20, 14, 15),
          isCompleted: true,
        ),
        ApprovalStepModel(
          title: 'Manager Approval Granted',
          actorName: 'Sarah Jenkins',
          actorRole: 'Engineering Manager',
          timestamp: DateTime(2026, 8, 21, 09, 45),
          isCompleted: true,
          comment: 'Approved. Valid business expense receipt attached.',
        ),
        ApprovalStepModel(
          title: 'Finance Disbursement Completed',
          actorName: 'Accounts Payable',
          actorRole: 'Finance',
          timestamp: DateTime(2026, 8, 22, 11, 00),
          isCompleted: true,
          comment: 'Reimbursement included in August 30 payroll cycle.',
        ),
      ],
    ),
    RequestModel(
      requestId: 'REQ-2026-001240',
      employeeId: 'EMP-8842',
      employeeName: 'Alex Morgan',
      employeeEmail: 'alex.morgan@acmeglobal.com',
      department: 'Engineering & Technology',
      managerEmail: 'sarah.jenkins@acmeglobal.com',
      requestType: RequestType.itSupport,
      requestData: {
        'issueCategory': 'Hardware Replacement',
        'deviceType': 'MacBook Pro M3 Max 16"',
        'priority': 'High',
        'description': 'Secondary USB-C Port 2 experiencing flickering display connection during external monitor output.',
      },
      attachments: ['display_error_screenshot.jpg'],
      status: RequestStatus.rejected,
      submittedAt: DateTime(2026, 8, 15, 11, 20),
      approvedAt: DateTime(2026, 8, 16, 16, 10),
      approver: 'IT Helpdesk Lead (Marcus Vance)',
      rejectionReason: 'Please bring laptop to 4th floor IT bar for a physical cable check before requesting a full motherboard replacement.',
      approvalHistory: [
        ApprovalStepModel(
          title: 'Request Submitted',
          actorName: 'Alex Morgan',
          actorRole: 'Employee',
          timestamp: DateTime(2026, 8, 15, 11, 20),
          isCompleted: true,
        ),
        ApprovalStepModel(
          title: 'IT Helpdesk Review - Rejected',
          actorName: 'Marcus Vance',
          actorRole: 'IT Operations Manager',
          timestamp: DateTime(2026, 8, 16, 16, 10),
          isCompleted: true,
          isRejected: true,
          comment: 'Please bring laptop to 4th floor IT bar for a physical cable check before requesting a full motherboard replacement.',
        ),
      ],
    ),
    RequestModel(
      requestId: 'REQ-2026-001235',
      employeeId: 'EMP-8842',
      employeeName: 'Alex Morgan',
      employeeEmail: 'alex.morgan@acmeglobal.com',
      department: 'Engineering & Technology',
      managerEmail: 'sarah.jenkins@acmeglobal.com',
      requestType: RequestType.workFromHome,
      requestData: {
        'startDate': '2026-08-10',
        'endDate': '2026-08-12',
        'reason': 'Fiber internet maintenance at home and remote deployment monitoring.',
      },
      attachments: [],
      status: RequestStatus.approved,
      submittedAt: DateTime(2026, 8, 08, 09, 00),
      approvedAt: DateTime(2026, 8, 08, 10, 15),
      approver: 'Sarah Jenkins',
      approvalHistory: [
        ApprovalStepModel(
          title: 'Request Submitted',
          actorName: 'Alex Morgan',
          actorRole: 'Employee',
          timestamp: DateTime(2026, 8, 08, 09, 00),
          isCompleted: true,
        ),
        ApprovalStepModel(
          title: 'Approved',
          actorName: 'Sarah Jenkins',
          actorRole: 'Engineering Manager',
          timestamp: DateTime(2026, 8, 08, 10, 15),
          isCompleted: true,
          comment: 'Enjoy remote work. Stay synced on Slack.',
        ),
      ],
    ),
  ];

  @override
  Future<List<RequestModel>> getEmployeeRequests(String employeeEmail) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockDatabase.where((r) => r.employeeEmail.toLowerCase() == employeeEmail.toLowerCase()).toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  @override
  Future<RequestModel> getRequestById(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _mockDatabase.firstWhere(
      (r) => r.requestId == requestId,
      orElse: () => throw Exception('Request $requestId not found'),
    );
  }

  @override
  Future<RequestModel> submitRequest(RequestModel newRequest) async {
    await Future.delayed(const Duration(milliseconds: 700));
    _mockDatabase.insert(0, newRequest);
    return newRequest;
  }

  @override
  Future<bool> cancelRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockDatabase.indexWhere((r) => r.requestId == requestId);
    if (index != -1) {
      final existing = _mockDatabase[index];
      _mockDatabase[index] = existing.copyWith(
        status: RequestStatus.cancelled,
        approvalHistory: [
          ...existing.approvalHistory,
          ApprovalStepModel(
            title: 'Request Cancelled by Employee',
            actorName: existing.employeeName,
            actorRole: 'Employee',
            timestamp: DateTime.now(),
            isCompleted: true,
          ),
        ],
      );
      return true;
    }
    return false;
  }
}
