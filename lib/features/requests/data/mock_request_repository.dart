import '../domain/approval_step_model.dart';
import '../domain/request_model.dart';
import '../domain/request_status.dart';
import 'request_repository.dart';

class MockRequestRepository implements IRequestRepository {
  final List<RequestModel> _mockDatabase = [];

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
