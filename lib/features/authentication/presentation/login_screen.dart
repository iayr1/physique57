import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final _emailController = TextEditingController(
    text: kIsWeb ? 'mayurailead@gmail.com' : '',
  );
  late final _passwordController = TextEditingController(
    text: kIsWeb ? 'mayur1675' : '',
  );
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  int _authModeTab = 0; // 0 = Email/Password, 1 = Google Workspace

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

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

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithEmailAndPassword(email, password);
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              message = 'No account found with this email. Contact your administrator.';
              break;
            case 'wrong-password':
            case 'invalid-credential':
              message = 'Incorrect password. Try again or tap "First time or setup password?" below.';
              break;
            case 'invalid-email':
              message = 'Invalid email address format.';
              break;
            case 'user-disabled':
              message = 'This account has been disabled.';
              break;
            default:
              message = e.message ?? e.code;
          }
        } else if (message.startsWith('Exception: ')) {
          message = message.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.statusRejected,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showSetupPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Setup or Reset Account Password',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your work email address. If an admin provisioned your account, we will send an email with instructions to set your password.',
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
            child: const Text('Cancel'),
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
                  content: Text('Password setup instructions sent to $targetEmail! Check your inbox.'),
                  backgroundColor: AppColors.statusApproved,
                ),
              );
            },
            child: const Text('Send Password Setup Email'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.cardGradient
              : const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                color: isDark ? AppColors.surfaceDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Enterprise Logo Badge
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.corporate_fare_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(duration: 500.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 20),
                      Text(
                        'ERMS Mobile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: 0.15, end: 0, delay: 100.ms, duration: 400.ms),
                      
                      const SizedBox(height: 4),
                      Text(
                        'Employee Request Management System',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 160.ms, duration: 400.ms)
                      .slideY(begin: 0.15, end: 0, delay: 160.ms, duration: 400.ms),
                      
                      if (!kIsWeb) ...[
                        // Auth Mode Segmented Control
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _authModeTab = 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _authModeTab == 0
                                          ? (isDark ? const Color(0xFF334155) : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _authModeTab == 0
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                          : null,
                                    ),
                                    child: Text(
                                      'Email & Password',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _authModeTab == 0
                                            ? (isDark ? Colors.white : AppColors.primary)
                                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _authModeTab = 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _authModeTab == 1
                                          ? (isDark ? const Color(0xFF334155) : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _authModeTab == 1
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                          : null,
                                    ),
                                    child: Text(
                                      'Google Workspace',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _authModeTab == 1
                                            ? (isDark ? Colors.white : AppColors.primary)
                                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 220.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, delay: 220.ms, duration: 400.ms),
                        const SizedBox(height: 24),
                      ],

                      // Animated Tab Switcher Container
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _authModeTab == 0
                            ? Column(
                                key: const ValueKey('email_form'),
                                children: [
                                  // Email Input
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Work Email Address',
                                      hintText: 'your.email@company.com',
                                      prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Password Input
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primary),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Forgot / Setup Password Link
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _showSetupPasswordDialog,
                                      child: Text(
                                        'First time or setup password?',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  CustomButton(
                                    text: 'Sign In with Email',
                                    isLoading: _isLoading,
                                    icon: Icons.login_rounded,
                                    onPressed: _handleEmailLogin,
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey('google_form'),
                                children: [
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
                                      foregroundColor: isDark ? Colors.white : Colors.black87,
                                      side: BorderSide(
                                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                        width: 1.2,
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isGoogleLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2.5),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.g_mobiledata_rounded,
                                                size: 28,
                                                color: Colors.blue,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Sign in with Google Workspace',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                      )
                      .animate()
                      .fadeIn(delay: 280.ms, duration: 400.ms)
                      .slideY(begin: 0.08, end: 0, delay: 280.ms, duration: 400.ms),

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
                      .fadeIn(delay: 480.ms, duration: 400.ms),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.97, 0.97),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
