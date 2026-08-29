import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/lottie_bottom_nav_bar.dart';
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
  final user = authState.valueOrNull;
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final isLoggedIn = user != null || firebaseUser != null;
  final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isAdminRoute = state.matchedLocation == '/admin';

      // Always let splash screen complete its transition naturally
      if (isSplash) return null;

      if (!hasCompletedOnboarding) {
        if (!isOnboarding) {
          return '/onboarding';
        }
        return null;
      }

      // If user is not logged in
      if (!isLoggedIn) {
        if (isOnboarding || isAdminRoute) return '/login';
        if (!isLoggingIn) return '/login';
        return null;
      }

      // If user is logged in
      if (isLoggedIn) {
        if (isLoggingIn || isOnboarding) {
          if (kIsWeb && (user?.isAdmin == true)) {
            return '/admin';
          }
          return '/';
        }
        // Protect admin route from non-admins
        if (isAdminRoute && user != null && !user.isAdmin) {
          return '/';
        }
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
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
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
            builder: (context, state) {
              final currentUser = ref.watch(authProvider).valueOrNull;
              if (kIsWeb && currentUser?.isAdmin == true) {
                return const AdminDashboardScreen();
              }
              return const DashboardScreen();
            },
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
    if (location.startsWith('/my-requests')) return 1;
    if (location.startsWith('/categories')) return 2;
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
        context.go('/my-requests');
        break;
      case 2:
        context.go('/categories');
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

    return Scaffold(
      body: child,
      bottomNavigationBar: LottieBottomNavBar(
        selectedIndex: selectedIndex,
        onItemTapped: (idx) => _onItemTapped(idx, context),
        unreadCount: unreadCount,
      ),
    );
  }
}
