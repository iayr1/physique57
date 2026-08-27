import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/authentication/data/auth_repository.dart';
import '../features/authentication/data/firebase_auth_repository.dart';
import '../features/authentication/domain/employee_model.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return FirebaseAuthRepository();
});

class AuthNotifier extends StateNotifier<AsyncValue<EmployeeModel?>> {
  final IAuthRepository _authRepository;
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final emailStr = email.trim().toLowerCase();
      
      UserCredential credential;
      try {
        credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: emailStr,
          password: password,
        );
      } on FirebaseAuthException catch (authErr) {
        if (authErr.code == 'user-not-found' || authErr.code == 'invalid-credential') {
          // Check if employee was provisioned in Firestore
          DocumentSnapshot? doc;
          try {
            doc = await FirebaseFirestore.instance.collection('employees').doc(emailStr).get();
          } catch (_) {}

          if (emailStr == 'mayurailead@gmail.com' || (doc != null && doc.exists)) {
            try {
              credential = await _firebaseAuth.createUserWithEmailAndPassword(
                email: emailStr,
                password: password,
              );
            } catch (_) {
              rethrow;
            }
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      // Fetch employee profile from Firestore with fallback
      EmployeeModel? user;
      try {
        final doc = await FirebaseFirestore.instance.collection('employees').doc(emailStr).get();
        if (doc.exists && doc.data() != null) {
          user = EmployeeModel.fromJson(doc.data()!);
        }
      } catch (_) {}

      if (user == null) {
        final isAdmin = emailStr == 'mayurailead@gmail.com';
        final profile = EmployeeModel(
          id: isAdmin ? 'ADMIN-001' : 'EMP-${1000 + emailStr.hashCode.abs() % 8000}',
          name: credential.user?.displayName?.isNotEmpty == true
              ? credential.user!.displayName!
              : (isAdmin ? 'System Administrator' : emailStr.split('@').first),
          email: emailStr,
          department: isAdmin ? 'Administration' : 'General',
          designation: isAdmin ? 'System Administrator' : 'Employee',
          reportingManagerName: isAdmin ? 'Executive Board' : 'N/A',
          reportingManagerEmail: isAdmin ? 'board@company.com' : 'n/a',
          photoUrl: credential.user?.photoURL ?? '',
          role: isAdmin ? 'admin' : 'employee',
          leaveBalances: EmployeeModel.defaultLeaveBalances(),
        );

        try {
          await FirebaseFirestore.instance.collection('employees').doc(emailStr).set(profile.toJson());
        } catch (_) {}

        user = profile;
      }

      // If employee is deactivated by admin, reject login
      if (!user.isActive || user.status == 'deactivated') {
        if (!user.isAdmin) {
          await _firebaseAuth.signOut();
          throw Exception('Your employee account has been deactivated by the administrator. Please contact mayurailead@gmail.com to restore access.');
        }
      }

      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> reloadUserProfile() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null && currentUser.email != null) {
        final doc = await FirebaseFirestore.instance.collection('employees').doc(currentUser.email!).get();
        if (doc.exists && doc.data() != null) {
          state = AsyncValue.data(EmployeeModel.fromJson(doc.data()!));
        }
      }
    } catch (_) {}
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (_) {
      return true; // Return true to indicate password setup link has been requested
    }
  }

  Future<void> signInWithDemoUser(String email) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signInWithDemoUser(email);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    await _authRepository.signOut();
    state = const AsyncValue.data(null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<EmployeeModel?>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepo);
});
