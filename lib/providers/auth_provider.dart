import 'dart:async';
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
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    checkCurrentUser();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  Future<void> checkCurrentUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);

      // Subscribe to real-time Firestore updates for leave balance sync
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser?.email != null) {
        _profileSubscription?.cancel();
        _profileSubscription = _firestore
            .collection('employees')
            .doc(currentUser!.email!.trim().toLowerCase())
            .snapshots()
            .listen((docSnap) {
          if (docSnap.exists && docSnap.data() != null) {
            state = AsyncValue.data(EmployeeModel.fromJson(docSnap.data()!));
          }
        });
      }
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
        // If user document was pre-provisioned by admin in Firestore, auto-create the Auth account
        if (authErr.code == 'user-not-found' || authErr.code == 'invalid-credential') {
          DocumentSnapshot? doc;
          try {
            doc = await _firestore.collection('employees').doc(emailStr).get();
          } catch (_) {}

          if (doc != null && doc.exists) {
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

      // Fetch employee profile from Firestore
      EmployeeModel? user;
      try {
        final doc = await _firestore.collection('employees').doc(emailStr).get();
        if (doc.exists && doc.data() != null) {
          user = EmployeeModel.fromJson(doc.data()!);
        }
      } catch (_) {}

      // Fallback if not found in Firestore yet
      if (user == null) {
        final profile = EmployeeModel(
          id: 'EMP-${1000 + emailStr.hashCode.abs() % 8000}',
          name: credential.user?.displayName?.isNotEmpty == true
              ? credential.user!.displayName!
              : emailStr.split('@').first,
          email: emailStr,
          department: 'Physique 57 Operations',
          designation: 'Team Member',
          reportingManagerName: 'Management Board',
          reportingManagerEmail: '',
          photoUrl: credential.user?.photoURL ?? '',
          role: 'employee',
          leaveBalances: EmployeeModel.defaultLeaveBalances(),
        );

        try {
          await _firestore.collection('employees').doc(emailStr).set(profile.toJson());
        } catch (_) {}

        user = profile;
      }

      // If employee is deactivated by admin, reject login
      if (!user.isActive || user.status == 'deactivated') {
        if (!user.isAdmin) {
          await _firebaseAuth.signOut();
          throw Exception('Your employee account has been deactivated. Please contact your administrator.');
        }
      }

      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String department,
    required String designation,
    String? reportingManagerName,
    String? reportingManagerEmail,
    String role = 'employee',
  }) async {
    state = const AsyncValue.loading();
    try {
      final emailStr = email.trim().toLowerCase();
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailStr,
        password: password,
      );

      final profile = EmployeeModel(
        id: 'EMP-${1000 + emailStr.hashCode.abs() % 8000}',
        name: name.trim(),
        email: emailStr,
        department: department.trim(),
        designation: designation.trim(),
        reportingManagerName: reportingManagerName?.trim() ?? 'Management Board',
        reportingManagerEmail: reportingManagerEmail?.trim() ?? '',
        photoUrl: credential.user?.photoURL ?? '',
        role: role,
        leaveBalances: EmployeeModel.defaultLeaveBalances(),
      );

      await _firestore.collection('employees').doc(emailStr).set(profile.toJson());

      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> reloadUserProfile() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null && currentUser.email != null) {
        final doc = await _firestore.collection('employees').doc(currentUser.email!.trim().toLowerCase()).get();
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
      return true;
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
