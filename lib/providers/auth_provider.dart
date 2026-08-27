import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/authentication/data/auth_repository.dart';
import '../features/authentication/data/firebase_auth_repository.dart';
import '../features/authentication/data/mock_auth_repository.dart';
import '../features/authentication/domain/employee_model.dart';
import 'theme_provider.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final backendType = ref.watch(backendTypeProvider);
  if (backendType == BackendType.firebase) {
    return FirebaseAuthRepository();
  }
  return MockAuthRepository();
});

class AuthNotifier extends StateNotifier<AsyncValue<EmployeeModel?>> {
  final IAuthRepository _authRepository;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Ref _ref;

  AuthNotifier(this._authRepository, this._ref) : super(const AsyncValue.loading()) {
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
      final emailStr = email.trim();
      
      // Attempt to sign in to Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: emailStr,
        password: password,
      );

      // Always fetch employee profile from Firestore
      EmployeeModel? user;
      final doc = await FirebaseFirestore.instance.collection('employees').doc(emailStr).get();
      if (doc.exists && doc.data() != null) {
        user = EmployeeModel.fromJson(doc.data()!);
      } else if (emailStr == 'mayurailead@gmail.com') {
        // Bootstrap admin profile into Firestore on first login
        final adminProfile = EmployeeModel(
          id: 'ADMIN-001',
          name: credential.user?.displayName ?? 'Admin',
          email: emailStr,
          department: 'Administration',
          designation: 'System Administrator',
          reportingManagerName: 'N/A',
          reportingManagerEmail: 'n/a',
          photoUrl: credential.user?.photoURL ?? '',
        );
        await FirebaseFirestore.instance.collection('employees').doc(emailStr).set(adminProfile.toJson());
        user = adminProfile;
      } else {
        // Not onboarded — sign out and reject
        await _firebaseAuth.signOut();
        throw Exception('Employee profile not found in database. Contact admin for onboarding.');
      }

      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
  return AuthNotifier(authRepo, ref);
});
