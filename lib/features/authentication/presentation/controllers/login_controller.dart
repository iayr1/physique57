import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';

class LoginState {
  final int authModeTab; // 0 = Sign In, 1 = Create Account
  final bool obscureSignInPassword;
  final bool obscureSignUpPassword;
  final bool isLoading;
  final String? errorMessage;

  const LoginState({
    this.authModeTab = 0,
    this.obscureSignInPassword = true,
    this.obscureSignUpPassword = true,
    this.isLoading = false,
    this.errorMessage,
  });

  LoginState copyWith({
    int? authModeTab,
    bool? obscureSignInPassword,
    bool? obscureSignUpPassword,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      authModeTab: authModeTab ?? this.authModeTab,
      obscureSignInPassword: obscureSignInPassword ?? this.obscureSignInPassword,
      obscureSignUpPassword: obscureSignUpPassword ?? this.obscureSignUpPassword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  final Ref _ref;

  LoginController(this._ref) : super(const LoginState());

  void setAuthModeTab(int tabIndex) {
    state = state.copyWith(authModeTab: tabIndex, clearError: true);
  }

  void toggleObscureSignInPassword() {
    state = state.copyWith(obscureSignInPassword: !state.obscureSignInPassword);
  }

  void toggleObscureSignUpPassword() {
    state = state.copyWith(obscureSignUpPassword: !state.obscureSignUpPassword);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ref.read(authProvider.notifier).signInWithEmailAndPassword(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String department,
    required String designation,
    required String managerName,
    required String managerEmail,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ref.read(authProvider.notifier).signUpWithEmailAndPassword(
            name: name,
            email: email,
            password: password,
            department: department,
            designation: designation,
            reportingManagerName: managerName,
            reportingManagerEmail: managerEmail,
            role: role,
          );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final loginControllerProvider = StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
  return LoginController(ref);
});
