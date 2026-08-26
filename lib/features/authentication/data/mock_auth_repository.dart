import '../domain/employee_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements IAuthRepository {
  EmployeeModel? _currentUser = EmployeeModel.demoUser;

  @override
  Future<EmployeeModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  @override
  Future<EmployeeModel> signInWithGoogle() async {
    // Simulates Google Workspace OAuth flow
    await Future.delayed(const Duration(milliseconds: 1000));
    _currentUser = EmployeeModel.demoUser;
    return EmployeeModel.demoUser;
  }

  @override
  Future<EmployeeModel> signInWithDemoUser(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = EmployeeModel(
      id: 'EMP-9901',
      name: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
      email: email,
      department: 'Product Operations',
      designation: 'Product Lead',
      reportingManagerName: 'David Vance',
      reportingManagerEmail: 'david.vance@acmeglobal.com',
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=250&q=80',
    );
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}
