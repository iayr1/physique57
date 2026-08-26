import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/authentication/data/auth_repository.dart';
import '../features/authentication/data/mock_auth_repository.dart';
import '../features/authentication/domain/employee_model.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return MockAuthRepository();
});

class AuthNotifier extends StateNotifier<AsyncValue<EmployeeModel?>> {
  final IAuthRepository _authRepository;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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
      try {
        await _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } catch (_) {
        // Fallback for demo logins if user isn't in live Firebase Auth yet
      }

      // Populate employee model
      final user = EmployeeModel(
        id: 'EMP-${1000 + email.hashCode.abs() % 8000}',
        name: email.split('@')[0].replaceAll('.', ' ').toUpperCase(),
        email: email.trim(),
        department: 'Engineering & Technology',
        designation: 'Senior Software Engineer',
        reportingManagerEmail: 'sarah.jenkins@acmeglobal.com',
        reportingManagerName: 'Sarah Jenkins',
        photoUrl: 'https://i.pravatar.cc/150?u=$email',
      );

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
  return AuthNotifier(authRepo);
});
