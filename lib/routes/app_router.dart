import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
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
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
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

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          height: 68,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
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
              label: 'New Request',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              label: 'My Requests',
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
              selectedIcon: const Icon(Icons.notifications_rounded, color: AppColors.primary),
              label: 'Notifications',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
