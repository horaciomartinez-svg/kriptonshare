import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../features/upload/presentation/screens/upload_screen.dart';
import '../features/links/presentation/screens/links_screen.dart';
import '../screens/viewer/viewer_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/biometric/biometric_settings_screen.dart';
import '../features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/auth';
      final isSplash = state.matchedLocation == '/';
      final isRoomRoute = state.matchedLocation.startsWith('/room/');

      if (isSplash) return null;

      if (!isAuthenticated && !isAuthRoute) {
        if (isRoomRoute) {
          // Preserve the room link so we can return after login.
          return '/auth?redirect=${Uri.encodeComponent(state.matchedLocation)}';
        }
        return '/auth';
      }

      if (isAuthenticated && isAuthRoute) {
        final redirect = state.uri.queryParameters['redirect'];
        if (redirect != null && redirect.isNotEmpty) {
          return redirect;
        }
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => AuthScreen(
          redirectPath: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: '/links',
        builder: (context, state) => const LinksScreen(),
      ),
      GoRoute(
        path: '/viewer',
        builder: (context, state) {
          final linkId = state.uri.queryParameters['id'];
          return ViewerScreen(linkId: linkId);
        },
      ),
      GoRoute(
        path: '/room/:id',
        builder: (context, state) {
          final linkId = state.pathParameters['id'];
          return ViewerScreen(linkId: linkId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      GoRoute(
        path: '/biometric',
        builder: (context, state) => const BiometricSettingsScreen(),
      ),
    ],
  );
});
