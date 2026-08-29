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
      badgeText: 'WORKFORCE HUB',
      title: 'Instant Requests & Approvals',
      description: 'Submit leave, travel, expense, and IT requests in seconds directly from your mobile device with real-time manager routing.',
      icon: Icons.rocket_launch_rounded,
      accentColor: AppColors.neoYellow,
    ),
    OnboardingPageData(
      badgeText: 'LIVE TRANSPARENCY',
      title: 'Real-Time Audit & Tracking',
      description: 'Track manager & HR approval timelines step-by-step with instant status notifications and total transparency.',
      icon: Icons.track_changes_rounded,
      accentColor: AppColors.neoCyan,
    ),
    OnboardingPageData(
      badgeText: 'SMART PAYROLL',
      title: 'Automated Payslips & Overtime',
      description: 'Download verified 6-month payslip statements and log overtime hours with automatic salary component calculations.',
      icon: Icons.payments_rounded,
      accentColor: AppColors.neoPink,
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
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;
    final lastPage = currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Brand Logo & Skip Chip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Mark Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.neoYellow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: 2),
                          boxShadow: [
                            BoxShadow(color: borderColor, offset: const Offset(2, 2), blurRadius: 0),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center_rounded, size: 20, color: AppColors.neoBorder),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PHYSIQUE 57',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : AppColors.neoBorder),
                      ),
                    ],
                  ),

                  // Skip Chip
                  AnimatedOpacity(
                    opacity: lastPage ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: lastPage,
                      child: GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            _pages.length - 1,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutQuint,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 2),
                            boxShadow: [
                              BoxShadow(color: borderColor, offset: const Offset(2, 2), blurRadius: 0),
                            ],
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.neoBorder),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View Content Cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Main Feature Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: borderColor, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor,
                                offset: const Offset(6, 6),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Feature Icon Container
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: page.accentColor,
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
                                child: Center(
                                  child: Icon(
                                    page.icon,
                                    size: 50,
                                    color: AppColors.neoBorder,
                                  ),
                                ),
                              )
                              .animate(key: ValueKey('icon-$index'))
                              .scale(duration: 500.ms, curve: Curves.easeOutBack)
                              .fadeIn(duration: 350.ms),

                              const SizedBox(height: 24),

                              // Badge Chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: page.accentColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.neoBorder, width: 2),
                                  boxShadow: const [
                                    BoxShadow(color: AppColors.neoBorder, offset: Offset(2, 2), blurRadius: 0),
                                  ],
                                ),
                                child: Text(
                                  page.badgeText,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.neoBorder,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Slide Title
                              Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : AppColors.neoBorder,
                                  letterSpacing: -0.2,
                                ),
                              )
                              .animate(key: ValueKey('title-$index'))
                              .fadeIn(delay: 150.ms, duration: 400.ms)
                              .slideY(begin: 0.15, end: 0, delay: 150.ms, duration: 400.ms),

                              const SizedBox(height: 12),

                              // Slide Description
                              Text(
                                page.description,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  height: 1.55,
                                ),
                              )
                              .animate(key: ValueKey('desc-$index'))
                              .fadeIn(delay: 250.ms, duration: 400.ms)
                              .slideY(begin: 0.15, end: 0, delay: 250.ms, duration: 400.ms),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Bar with Neo-Brutalist Indicators & Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Neo-Brutalist Rectangular Page Indicators
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final isSelected = currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: isSelected ? 32 : 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _pages[currentPage].accentColor
                              : (isDark ? AppColors.surfaceDark : Colors.white),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor, width: 2),
                          boxShadow: isSelected
                              ? [BoxShadow(color: borderColor, offset: const Offset(2, 2), blurRadius: 0)]
                              : null,
                        ),
                      );
                    }),
                  ),

                  // Neo-Brutalist Action Button
                  GestureDetector(
                    onTap: lastPage
                        ? _handleGetStarted
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: lastPage ? AppColors.neoGreen : AppColors.neoYellow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.neoBorder, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.neoBorder,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lastPage ? 'Get Started' : 'Next',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.neoBorder,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: AppColors.neoBorder,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String badgeText;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  OnboardingPageData({
    required this.badgeText,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}
