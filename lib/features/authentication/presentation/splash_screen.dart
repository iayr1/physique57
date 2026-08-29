import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startNavigationTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNavigationTimer() {
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && !_hasNavigated) {
        _checkStatusAndNavigate();
      }
    });
  }

  void _checkStatusAndNavigate() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final user = ref.read(authProvider).valueOrNull;
    final isLoggedIn = user != null || firebaseUser != null;
    final hasCompletedOnboarding = ref.read(hasCompletedOnboardingProvider);

    if (isLoggedIn) {
      context.go('/');
    } else if (!hasCompletedOnboarding) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _checkStatusAndNavigate,
        child: ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Neo-Brutalist Geometric Accent Blocks
              Positioned(
                top: -30,
                left: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.neoYellow,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: borderColor, width: 3.5),
                    boxShadow: [
                      BoxShadow(color: borderColor, offset: const Offset(6, 6), blurRadius: 0),
                    ],
                  ),
                ).animate().scale(duration: 700.ms, curve: Curves.easeOutBack),
              ),
              Positioned(
                bottom: -40,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.neoCyan,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: borderColor, width: 3.5),
                    boxShadow: [
                      BoxShadow(color: borderColor, offset: const Offset(8, 8), blurRadius: 0),
                    ],
                  ),
                ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
              ),
              Positioned(
                top: 100,
                right: -25,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.neoPink,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 3),
                    boxShadow: [
                      BoxShadow(color: borderColor, offset: const Offset(4, 4), blurRadius: 0),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ),

              // Main Safe Responsive Structure
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 20),

                      // Center Hero Card
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.88,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: borderColor, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor,
                                offset: const Offset(7, 7),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Brand Logo Mark in Neo-Brutalist Badge
                              Container(
                                width: 88,
                                height: 88,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.neoYellow,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: AppColors.neoBorder, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.neoBorder,
                                      offset: Offset(4, 4),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.fitness_center_rounded,
                                    size: 42,
                                    color: AppColors.neoBorder,
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .scale(duration: 600.ms, curve: Curves.easeOutBack),

                              const SizedBox(height: 20),

                              // App Title
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'PHYSIQUE 57',
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : AppColors.neoBorder,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 400.ms)
                              .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),

                              const SizedBox(height: 8),

                              // Tag Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.neoCyan,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.neoBorder, width: 2),
                                  boxShadow: const [
                                    BoxShadow(color: AppColors.neoBorder, offset: Offset(2, 2), blurRadius: 0),
                                  ],
                                ),
                                child: Text(
                                  'ENTERPRISE ERMS HUB',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.neoBorder,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 400.ms),

                              const SizedBox(height: 12),

                              Text(
                                'Workforce & Request Management',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[600],
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 400.ms),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Loading Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 2.5),
                          boxShadow: [
                            BoxShadow(color: borderColor, offset: const Offset(3, 3), blurRadius: 0),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.8,
                                valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : AppColors.neoBorder),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Loading Workspace...',
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white : AppColors.neoBorder,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
