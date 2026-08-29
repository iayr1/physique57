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
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
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

  void _showSetupPasswordDialog() {
    final resetEmailController = TextEditingController(text: _signInEmailController.text.trim());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 2.5),
        ),
        title: Text(
          'Setup or Reset Password',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 19),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered work email address to receive password setup instructions via Firebase.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                hintText: 'your.email@physique57.com',
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.neoBorder),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neoYellow),
            onPressed: () async {
              final targetEmail = resetEmailController.text.trim();
              if (targetEmail.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);

              await ref.read(authProvider.notifier).sendPasswordResetEmail(targetEmail);
              navigator.pop();

              messenger.showSnackBar(
                SnackBar(
                  content: Text('Password reset instructions sent to $targetEmail! Check your inbox.'),
                  backgroundColor: AppColors.statusApproved,
                ),
              );
            },
            child: Text('Send Reset Link', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppColors.neoBorder)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: borderColor,
                    offset: const Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Logo & Branding Badge
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.neoYellow,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: borderColor,
                              offset: const Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
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
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: isDark ? Colors.white : AppColors.neoBorder,
                      ),
                    ),
                    Text(
                      'Enterprise Staff Portal',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign In Form
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _signInEmailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'Work Email Address',
                            hintText: 'your.email@physique57.com',
                            prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.neoBorder),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor, width: 2.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _signInPasswordController,
                          obscureText: loginState.obscureSignInPassword,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.neoBorder),
                            suffixIcon: IconButton(
                              icon: Icon(
                                loginState.obscureSignInPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.neoBorder,
                              ),
                              onPressed: () => ref.read(loginControllerProvider.notifier).toggleObscureSignInPassword(),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor, width: 2.5),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.neoYellow : AppColors.neoIndigo,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        CustomButton(
                          text: 'Sign In to Workspace',
                          isLoading: loginState.isLoading,
                          icon: Icons.login_rounded,
                          onPressed: _handleSignIn,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Informational Admin Provisioning Note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.neoBgDark : AppColors.neoCyan.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_outlined, color: AppColors.neoBorder, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'New employee accounts are provisioned exclusively by Management via the Admin Portal.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.neoBorder,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Secured by Firebase Authentication & Cloud Firestore.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
    );
  }
}
