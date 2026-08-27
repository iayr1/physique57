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

    final authState = ref.read(authProvider);
    bool isLoggedIn = authState.valueOrNull != null;
    try {
      if (!isLoggedIn && FirebaseAuth.instance.currentUser != null) {
        isLoggedIn = true;
      }
    } catch (_) {}

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

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _checkStatusAndNavigate,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.cardGradient
                : const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF3730A3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background soft shapes
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                right: -50,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              
              // Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Enterprise Logo Badge
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.corporate_fare_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(duration: 500.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 24),
                  
                  // App Title
                  Text(
                    'Physique 57 ERMS',
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),
                  
                  const SizedBox(height: 6),
                  
                  // App Description
                  Text(
                    'Employee Request Management System',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms),
                ],
              ),
              
              // Bottom Loading Indicator
              Positioned(
                bottom: 50,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Starting workspace...',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
