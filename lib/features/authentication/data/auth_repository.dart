import '../domain/employee_model.dart';

abstract class IAuthRepository {
  Future<EmployeeModel?> getCurrentUser();
  Future<EmployeeModel> signInWithGoogle();
  Future<EmployeeModel> signInWithDemoUser(String email);
  Future<void> signOut();
}
