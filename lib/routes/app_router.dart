import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/requests/presentation/categories_screen.dart';
import '../features/requests/presentation/forms/attendance_form.dart';
import '../features/requests/presentation/forms/expense_request_form.dart';
import '../features/requests/presentation/forms/generic_request_form.dart';
import '../features/requests/presentation/forms/hr_request_form.dart';
import '../features/requests/presentation/forms/it_support_form.dart';
import '../features/requests/presentation/forms/leave_request_form.dart';
import '../features/requests/presentation/forms/travel_request_form.dart';
import '../features/requests/presentation/forms/wfh_form.dart';
import '../features/requests/presentation/my_requests_screen.dart';
import '../features/requests/presentation/request_detail_screen.dart';
import '../features/authentication/presentation/splash_screen.dart';
import '../features/authentication/presentation/onboarding_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Let splash screen flow bypass routing redirects
      if (isSplash) return null;

      if (!hasCompletedOnboarding) {
        if (!isOnboarding) {
          return '/onboarding';
        }
        return null;
      }

      // If onboarding is completed but user is not logged in
      if (!isLoggedIn) {
        if (isOnboarding) return '/login';
        if (!isLoggingIn) return '/login';
        return null;
      }

      // If user is logged in
      if (isLoggedIn) {
        if (isLoggingIn || isOnboarding) return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          if (kIsWeb) return child;
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => kIsWeb ? const AdminDashboardScreen() : const DashboardScreen(),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/my-requests',
            builder: (context, state) => const MyRequestsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Form Routes (Pushed on root navigator over bottom bar)
      GoRoute(
        path: '/forms/leave',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LeaveRequestForm(),
      ),
      GoRoute(
        path: '/forms/expense',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpenseRequestForm(),
      ),
      GoRoute(
        path: '/forms/it',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ITSupportForm(),
      ),
      GoRoute(
        path: '/forms/attendance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AttendanceForm(),
      ),
      GoRoute(
        path: '/forms/wfh',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WFHForm(),
      ),
      GoRoute(
        path: '/forms/hr',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HRRequestForm(),
      ),
      GoRoute(
        path: '/forms/travel',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TravelRequestForm(),
      ),
      GoRoute(
        path: '/forms/generic',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GenericRequestForm(),
      ),
      GoRoute(
        path: '/requests/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RequestDetailScreen(requestId: id);
        },
      ),
    ],
  );
});

class ScaffoldWithBottomNavBar extends ConsumerWidget {
  final Widget child;
  const ScaffoldWithBottomNavBar({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/categories')) return 1;
    if (location.startsWith('/my-requests')) return 2;
    if (location.startsWith('/notifications')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/categories');
        break;
      case 2:
        context.go('/my-requests');
        break;
      case 3:
        context.go('/notifications');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 72,
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.primary,
                );
              }
              return GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(
                  size: 22,
                  color: isDark ? Colors.white : AppColors.primary,
                );
              }
              return IconThemeData(
                size: 22,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (idx) => _onItemTapped(idx, context),
            elevation: 0,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                ),
                label: 'New',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Requests',
              ),
              NavigationDestination(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.statusRejected,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                        ),
                      ),
                  ],
                ),
                selectedIcon: const Icon(Icons.notifications_rounded),
                label: 'Alerts',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
