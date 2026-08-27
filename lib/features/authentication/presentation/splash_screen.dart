import 'dart:async';
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
    // Keep splash visible for at least 2.5 seconds for visual branding
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _checkStatusAndNavigate();
      }
    });
  }

  void _checkStatusAndNavigate() {
    if (!mounted) return;

    final authState = ref.read(authProvider);

    // If auth state is still loading, wait and retry shortly
    if (authState.isLoading) {
      _timer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          _checkStatusAndNavigate();
        }
      });
      return;
    }

    final isLoggedIn = authState.valueOrNull != null;
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
      body: Container(
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
            // Ambient soft glowing background shapes
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
                // Animated Enterprise Logo Badge
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.corporate_fare_rounded,
                    size: 52,
                    color: AppColors.primary,
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack)
                .then(delay: 400.ms)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.06, duration: 1500.ms, curve: Curves.easeInOut),
                
                const SizedBox(height: 28),
                
                // Animated App Title
                Text(
                  'ERMS Mobile',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 600.ms, curve: Curves.easeOutQuad),
                
                const SizedBox(height: 6),
                
                // Animated App Description
                Text(
                  'Employee Request Management System',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                )
                .animate()
                .fadeIn(delay: 700.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0, delay: 700.ms, duration: 600.ms, curve: Curves.easeOutQuad),
              ],
            ),
            
            // Bottom Loading Indicator
            Positioned(
              bottom: 60,
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading workspace...',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 1000.ms, duration: 500.ms),
            ),
          ],
        ),
      ),
    );
  }
}
