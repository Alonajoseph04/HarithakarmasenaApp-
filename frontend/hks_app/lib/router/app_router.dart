import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/landing_screen.dart';
import '../screens/admin/admin_login.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/dashboard_screen.dart';
import '../screens/admin/worker_management_screen.dart';
import '../screens/admin/household_management_screen.dart';
import '../screens/admin/ward_management_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/admin/broadcast_screen.dart';
import '../screens/worker/worker_login.dart';
import '../screens/worker/worker_shell.dart';
import '../screens/worker/ward_progress_screen.dart';
import '../screens/worker/scanner_screen.dart';
import '../screens/worker/collection_form_screen.dart';
import '../screens/worker/worker_dashboard_screen.dart';
import '../screens/household/household_login.dart';
import '../screens/household/household_shell.dart';
import '../screens/household/household_dashboard_screen.dart';
import '../screens/household/collection_history_screen.dart';
import '../screens/household/payment_history_screen.dart';
import '../screens/household/waste_insights_screen.dart';
import '../screens/household/waste_guidelines_screen.dart';
import '../screens/household/worker_contact_screen.dart';
import '../screens/household/skip_collection_screen.dart';
import '../screens/household/worker_feedback_screen.dart';
import '../screens/household/household_payment_screen.dart';
import '../screens/household/extra_pickup_screen.dart';
import '../screens/worker/extra_pickup_requests_screen.dart';
import '../screens/shared/notifications_screen.dart';

/// Splash screen shown while auth state loads from SharedPreferences.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

/// Build the router, using [auth] as a refreshListenable so redirects
/// are re-evaluated every time auth state changes (login / logout / init).
GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      if (!auth.isInitialized) return '/_splash';

      final loc = state.matchedLocation;
      final loggedIn = auth.isLoggedIn;
      final role = auth.role;

      const publicRoutes = ['/', '/admin/login', '/worker/login', '/household/login', '/_splash'];
      final isPublic = publicRoutes.contains(loc);

      // Unauthenticated → protected route: redirect to landing
      if (!loggedIn && !isPublic) return '/';

      // Authenticated → landing/login: redirect to correct dashboard
      if (loggedIn && isPublic && loc != '/_splash') {
        if (role == 'admin') return '/admin';
        if (role == 'worker') return '/worker';
        if (role == 'household') return '/household';
      }

      // Role-based enforcement
      if (loggedIn) {
        if (loc.startsWith('/admin') && loc != '/admin/login' && role != 'admin') return '/';
        if (loc.startsWith('/worker') && loc != '/worker/login' && role != 'worker') return '/';
        if (loc.startsWith('/household') && loc != '/household/login' && role != 'household') return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (ctx, state) => const LandingScreen()),
      GoRoute(path: '/_splash', builder: (ctx, state) => const _SplashScreen()),

      // Admin
      GoRoute(path: '/admin/login', builder: (ctx, state) => const AdminLoginScreen()),
      ShellRoute(
        builder: (ctx, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin', builder: (ctx, state) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/workers', builder: (ctx, state) => const WorkerManagementScreen()),
          GoRoute(path: '/admin/households', builder: (ctx, state) => const HouseholdManagementScreen()),
          GoRoute(path: '/admin/wards', builder: (ctx, state) => const WardManagementScreen()),
          GoRoute(path: '/admin/reports', builder: (ctx, state) => const ReportsScreen()),
          GoRoute(path: '/admin/broadcast', builder: (ctx, state) => const BroadcastScreen()),
          GoRoute(path: '/admin/notifications', builder: (ctx, state) => const NotificationsScreen()),
        ],
      ),

      // Worker
      GoRoute(path: '/worker/login', builder: (ctx, state) => const WorkerLoginScreen()),
      ShellRoute(
        builder: (ctx, state, child) => WorkerShell(child: child),
        routes: [
          GoRoute(path: '/worker', builder: (ctx, state) => const WardProgressScreen()),
          GoRoute(path: '/worker/scan', builder: (ctx, state) => const ScannerScreen()),
          GoRoute(
            path: '/worker/collect',
            builder: (ctx, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CollectionFormScreen(householdData: extra ?? {});
            },
          ),
          GoRoute(path: '/worker/stats', builder: (ctx, state) => const WorkerDashboardScreen()),
          GoRoute(path: '/worker/notifications', builder: (ctx, state) => const NotificationsScreen()),
          GoRoute(path: '/worker/extra-requests', builder: (ctx, state) => const ExtraPickupRequestsScreen()),
        ],
      ),

      // Household
      GoRoute(path: '/household/login', builder: (ctx, state) => const HouseholdLoginScreen()),
      ShellRoute(
        builder: (ctx, state, child) => HouseholdShell(child: child),
        routes: [
          GoRoute(path: '/household', builder: (ctx, state) => const HouseholdDashboardScreen()),
          GoRoute(path: '/household/history', builder: (ctx, state) => const CollectionHistoryScreen()),
          GoRoute(path: '/household/payments', builder: (ctx, state) => const PaymentHistoryScreen()),
          GoRoute(path: '/household/insights', builder: (ctx, state) => const WasteInsightsScreen()),
          GoRoute(path: '/household/notifications', builder: (ctx, state) => const NotificationsScreen()),
          GoRoute(path: '/household/guidelines', builder: (ctx, state) => const WasteGuidelinesScreen()),
          GoRoute(path: '/household/worker-contact', builder: (ctx, state) => const WorkerContactScreen()),
          GoRoute(path: '/household/skip', builder: (ctx, state) => const SkipCollectionScreen()),
          GoRoute(path: '/household/pay', builder: (ctx, state) => const HouseholdPaymentScreen()),
          GoRoute(
            path: '/household/feedback',
            builder: (ctx, state) {
              final collection = state.extra as Map<String, dynamic>? ?? {};
              return WorkerFeedbackScreen(collection: collection);
            },
          ),
          GoRoute(path: '/household/extra-pickup', builder: (ctx, state) => const ExtraPickupScreen()),
        ],
      ),
    ],
  );
}
