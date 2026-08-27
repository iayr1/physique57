import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/employee_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _employeesCollection =>
      _firestore.collection('employees');

  @override
  Future<EmployeeModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final email = firebaseUser.email;
    if (email == null) return null;

    // Always fetch from Firestore — no hardcoded profiles
    final doc = await _employeesCollection.doc(email).get();
    if (doc.exists && doc.data() != null) {
      return EmployeeModel.fromJson(doc.data()!);
    }

    // If admin logs in for the first time and has no Firestore profile yet, bootstrap it
    if (email == 'mayurailead@gmail.com') {
      final adminProfile = EmployeeModel(
        id: 'ADMIN-001',
        name: firebaseUser.displayName ?? 'Admin',
        email: email,
        department: 'Administration',
        designation: 'System Administrator',
        reportingManagerName: 'N/A',
        reportingManagerEmail: 'n/a',
        photoUrl: firebaseUser.photoURL ?? '',
      );
      await _employeesCollection.doc(email).set(adminProfile.toJson());
      return adminProfile;
    }

    return null;
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
