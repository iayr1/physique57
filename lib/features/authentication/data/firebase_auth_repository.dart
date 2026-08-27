import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/employee_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _employeesCollection =>
      _firestore.collection('employees');

  @override
  Future<EmployeeModel?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      final email = firebaseUser.email;
      if (email == null) return null;

      // Fetch from Firestore with fallback
      try {
        final doc = await _employeesCollection.doc(email).get();
        if (doc.exists && doc.data() != null) {
          return EmployeeModel.fromJson(doc.data()!);
        }
      } catch (_) {}

      // Fallback profile from authenticated Firebase User
      final isAdmin = email.trim().toLowerCase() == 'mayurailead@gmail.com';
      final profile = EmployeeModel(
        id: isAdmin ? 'ADMIN-001' : 'EMP-${1000 + email.hashCode.abs() % 8000}',
        name: firebaseUser.displayName?.isNotEmpty == true
            ? firebaseUser.displayName!
            : (isAdmin ? 'System Administrator' : email.split('@').first),
        email: email,
        department: isAdmin ? 'Administration' : 'General',
        designation: isAdmin ? 'System Administrator' : 'Employee',
        reportingManagerName: isAdmin ? 'Executive Board' : 'N/A',
        reportingManagerEmail: isAdmin ? 'board@company.com' : 'n/a',
        photoUrl: firebaseUser.photoURL ?? '',
        role: isAdmin ? 'admin' : 'employee',
        leaveBalances: EmployeeModel.defaultLeaveBalances(),
      );

      try {
        await _employeesCollection.doc(email).set(profile.toJson());
      } catch (_) {}

      return profile;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<EmployeeModel> signInWithGoogle() async {
    // Google Sign-In is not used in production; throw meaningful error
    throw UnimplementedError('Google Workspace sign-in is not configured for this project.');
  }

  @override
  Future<EmployeeModel> signInWithDemoUser(String email) async {
    // Demo users are removed in production. Attempt real Firebase Auth login.
    throw UnimplementedError('Demo accounts are disabled. Use real credentials.');
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
