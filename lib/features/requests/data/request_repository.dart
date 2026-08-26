import '../domain/request_model.dart';

abstract class IRequestRepository {
  Future<List<RequestModel>> getEmployeeRequests(String employeeEmail);
  Future<RequestModel> getRequestById(String requestId);
  Future<RequestModel> submitRequest(RequestModel newRequest);
  Future<bool> cancelRequest(String requestId);
}
