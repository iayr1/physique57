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

      final email = firebaseUser.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) return null;

      // Fetch from Firestore with strict timeout fallback so splash screen never hangs
      try {
        final doc = await _employeesCollection.doc(email).get().timeout(const Duration(seconds: 3));
        if (doc.exists && doc.data() != null) {
          return EmployeeModel.fromJson(doc.data()!);
        }
      } catch (_) {}

      // Fallback profile from authenticated Firebase User if Firestore record doesn't exist yet
      final profile = EmployeeModel(
        id: 'EMP-${1000 + email.hashCode.abs() % 8000}',
        name: firebaseUser.displayName?.isNotEmpty == true
            ? firebaseUser.displayName!
            : email.split('@').first,
        email: email,
        department: 'Physique 57 Operations',
        designation: 'Team Member',
        reportingManagerName: 'Management Board',
        reportingManagerEmail: '',
        photoUrl: firebaseUser.photoURL ?? '',
        role: 'employee',
        leaveBalances: EmployeeModel.defaultLeaveBalances(),
      );

      try {
        _employeesCollection.doc(email).set(profile.toJson()).timeout(const Duration(seconds: 3)).ignore();
      } catch (_) {}

      return profile;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<EmployeeModel> signInWithGoogle() async {
    throw UnimplementedError('Google Workspace sign-in is not configured for this project.');
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
