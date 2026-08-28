import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/auth_provider.dart';
import 'controllers/login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Sign In Controllers
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  // Sign Up Controllers
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpDeptController = TextEditingController();
  final _signUpDesignationController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpDeptController.dispose();
    _signUpDesignationController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _signInEmailController.text.trim();
    final password = _signInPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid work email address')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    final success = await ref.read(loginControllerProvider.notifier).signIn(email, password);
    if (!success && mounted) {
      final err = ref.read(loginControllerProvider).errorMessage ?? 'Authentication failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.statusRejected,
        ),
      );
    }
  }

  Future<void> _handleSignUp() async {
    final name = _signUpNameController.text.trim();
    final email = _signUpEmailController.text.trim();
    final dept = _signUpDeptController.text.trim();
    final desig = _signUpDesignationController.text.trim();
    final password = _signUpPasswordController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid work email address')),
      );
      return;
    }

    if (dept.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your department or studio')),
      );
      return;
    }

    if (desig.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your designation / role')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    final success = await ref.read(loginControllerProvider.notifier).signUp(
          name: name,
          email: email,
          password: password,
          department: dept,
          designation: desig,
          managerName: 'Management',
          managerEmail: 'admin@physique57.com',
          role: 'employee',
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome $name! Your employee profile is active.'),
          backgroundColor: AppColors.statusApproved,
        ),
      );
    } else if (!success && mounted) {
      final err = ref.read(loginControllerProvider).errorMessage ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.statusRejected,
        ),
      );
    }
  }

  void _showSetupPasswordDialog() {
    final resetEmailController = TextEditingController(text: _signInEmailController.text.trim());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Setup or Reset Password',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your work email address to receive password setup instructions via Firebase.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                hintText: 'your.email@company.com',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final targetEmail = resetEmailController.text.trim();
              if (targetEmail.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);

              await ref.read(authProvider.notifier).sendPasswordResetEmail(targetEmail);
              navigator.pop();

              messenger.showSnackBar(
                SnackBar(
                  content: Text('Password instructions sent to $targetEmail! Check your inbox.'),
                  backgroundColor: AppColors.statusApproved,
                ),
              );
            },
            child: Text('Send Reset Link', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo & Branding Badge
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: AppColors.luxuryGradient,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.fitness_center_rounded, size: 34, color: Colors.white),
                          ),
                        ),
                      )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 16),

                      Text(
                        'PHYSIQUE 57',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Enterprise Resource Management',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Segmented Tab Switcher (Sign In vs Create Account)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => ref.read(loginControllerProvider.notifier).setAuthModeTab(0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: loginState.authModeTab == 0
                                        ? (isDark ? const Color(0xFF334155) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: loginState.authModeTab == 0
                                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                        : null,
                                  ),
                                  child: Text(
                                    'Sign In',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: loginState.authModeTab == 0
                                          ? (isDark ? Colors.white : AppColors.primary)
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => ref.read(loginControllerProvider.notifier).setAuthModeTab(1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: loginState.authModeTab == 1
                                        ? (isDark ? const Color(0xFF334155) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: loginState.authModeTab == 1
                                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                        : null,
                                  ),
                                  child: Text(
                                    'Create Account',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: loginState.authModeTab == 1
                                          ? (isDark ? Colors.white : AppColors.primary)
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Animated Tab Content Switcher
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: loginState.authModeTab == 0
                            ? Column(
                                key: const ValueKey('sign_in_form'),
                                children: [
                                  TextFormField(
                                    controller: _signInEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Work Email Address',
                                      hintText: 'your.email@physique57.com',
                                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _signInPasswordController,
                                    obscureText: loginState.obscureSignInPassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primary),
                                      suffixIcon: IconButton(
                                        icon: Icon(loginState.obscureSignInPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                        onPressed: () => ref.read(loginControllerProvider.notifier).toggleObscureSignInPassword(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _showSetupPasswordDialog,
                                      child: Text(
                                        'Forgot / Setup password?',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  CustomButton(
                                    text: 'Sign In to Workspace',
                                    isLoading: loginState.isLoading,
                                    icon: Icons.login_rounded,
                                    onPressed: _handleSignIn,
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey('sign_up_form'),
                                children: [
                                  TextFormField(
                                    controller: _signUpNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Full Name',
                                      hintText: 'e.g. Sarah Connor',
                                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _signUpEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Work Email Address',
                                      hintText: 'e.g. sarah@physique57.com',
                                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _signUpDeptController,
                                          decoration: const InputDecoration(
                                            labelText: 'Department / Studio',
                                            hintText: 'e.g. Studio Ops',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _signUpDesignationController,
                                          decoration: const InputDecoration(
                                            labelText: 'Designation',
                                            hintText: 'e.g. Lead Trainer',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _signUpPasswordController,
                                    obscureText: loginState.obscureSignUpPassword,
                                    decoration: InputDecoration(
                                      labelText: 'Create Password',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primary),
                                      suffixIcon: IconButton(
                                        icon: Icon(loginState.obscureSignUpPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                        onPressed: () => ref.read(loginControllerProvider.notifier).toggleObscureSignUpPassword(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  CustomButton(
                                    text: 'Register Employee Account',
                                    isLoading: loginState.isLoading,
                                    icon: Icons.person_add_alt_1_rounded,
                                    onPressed: _handleSignUp,
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Secured by Firebase Authentication & Cloud Firestore.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
