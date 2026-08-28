import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/theme_provider.dart';
import 'controllers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Simplify Requests',
      description: 'Submit and manage leave, travel, and expense requests in seconds directly from your phone.',
      icon: Icons.receipt_long_rounded,
      color: AppColors.primary,
      bgGradient: const LinearGradient(
        colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      darkBgGradient: const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    OnboardingPageData(
      title: 'Visual Timelines',
      description: 'Track approvals step-by-step. Get clear transparency on who is reviewing your request and when.',
      icon: Icons.timeline_rounded,
      color: AppColors.secondary,
      bgGradient: const LinearGradient(
        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      darkBgGradient: const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF064E3B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    OnboardingPageData(
      title: 'Smart Alerts',
      description: 'Receive instant notifications and push updates the second your request status changes.',
      icon: Icons.notifications_active_rounded,
      color: AppColors.accent,
      bgGradient: const LinearGradient(
        colors: [Color(0xFFFFF1F2), Color(0xFFFFFFE4)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      darkBgGradient: const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF581C87)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(onboardingPageProvider.notifier).state = index;
  }

  void _handleGetStarted() {
    ref.read(hasCompletedOnboardingProvider.notifier).state = true;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingPageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lastPage = currentPage == _pages.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: isDark
              ? _pages[currentPage].darkBgGradient
              : _pages[currentPage].bgGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip Button
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: AnimatedOpacity(
                    opacity: lastPage ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: lastPage,
                      child: TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            _pages.length - 1,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutQuint,
                          );
                        },
                        child: Text(
                          'Skip',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Page Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Graphic Icon Container
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? page.color.withValues(alpha: 0.15)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: page.color.withValues(alpha: 0.3),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: page.color.withValues(alpha: 0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                page.icon,
                                size: 76,
                                color: page.color,
                              ),
                            ),
                          )
                          .animate(key: ValueKey('icon-$index'))
                          .scale(duration: 600.ms, curve: Curves.easeOutBack)
                          .fadeIn(duration: 400.ms),
                          
                          const SizedBox(height: 48),
                          
                          // Slide Title
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              letterSpacing: -0.5,
                            ),
                          )
                          .animate(key: ValueKey('title-$index'))
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 500.ms),
                          
                          const SizedBox(height: 16),
                          
                          // Slide Description
                          Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              height: 1.5,
                            ),
                          )
                          .animate(key: ValueKey('desc-$index'))
                          .fadeIn(delay: 350.ms, duration: 500.ms)
                          .slideY(begin: 0.2, end: 0, delay: 350.ms, duration: 500.ms),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Navigation & Indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dot Indicators
                    Row(
                      children: List.generate(_pages.length, (index) {
                        final isSelected = currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: isSelected ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _pages[currentPage].color
                                : (isDark ? Colors.white24 : Colors.black12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    // Navigation Button
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(scale: animation, child: child),
                        );
                      },
                      child: lastPage
                          ? SizedBox(
                              key: const ValueKey('get_started_btn'),
                              width: 150,
                              child: ElevatedButton(
                                onPressed: _handleGetStarted,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _pages[currentPage].color,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Get Started',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              ),
                            )
                          : IconButton.filled(
                              key: const ValueKey('next_btn'),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: _pages[currentPage].color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
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

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Gradient bgGradient;
  final Gradient darkBgGradient;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgGradient,
    required this.darkBgGradient,
  });
}
