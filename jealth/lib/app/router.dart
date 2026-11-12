import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/storage/storage_providers.dart';
import '../core/widgets/state_views.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/classification/screens/classification_screen.dart';
import '../features/history/screens/history_detail_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/learn/screens/learn_screen.dart';
import '../features/onboarding/providers/onboarding_controller.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/results/screens/result_screen.dart';
import '../features/settings/screens/about_screen.dart';
import '../features/settings/screens/model_info_screen.dart';
import '../features/settings/screens/privacy_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

/// Application router.
///
/// Start-up flow: `/splash` is shown while preferences load, then the router
/// redirects to onboarding (first launch) or to the requested location.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(appStartupProvider, (_, _) => refresh.value++);
  ref.listen(onboardingControllerProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'root'),
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state),
    errorBuilder: (context, state) => const _NotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            _fadePage(state, const OnboardingScreen()),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) =>
            _fadePage(state, AppShell(navigationShell: navigationShell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.classify,
                builder: (context, state) => const ClassificationScreen(),
                routes: [
                  GoRoute(
                    path: 'result',
                    builder: (context, state) => const ResultScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => HistoryDetailScreen(
                      recordId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.analytics,
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.learn,
                builder: (context, state) => const LearnScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: 'model',
            builder: (context, state) => const ModelInfoScreen(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

String? _redirect(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;
  final atSplash = location == AppRoutes.splash;

  // Still initialising: hold every request on the splash screen and remember
  // where the user wanted to go (matters for web deep links and refreshes).
  if (!ref.read(appStartupProvider).hasValue) {
    if (atSplash) return null;
    return Uri(
      path: AppRoutes.splash,
      queryParameters: {'from': state.uri.toString()},
    ).toString();
  }

  final onboarded = ref.read(onboardingControllerProvider);
  if (atSplash) {
    if (!onboarded) return AppRoutes.onboarding;
    final from = state.uri.queryParameters['from'];
    final isSafeTarget =
        from != null &&
        from.startsWith('/') &&
        !from.startsWith('//') &&
        !from.startsWith(AppRoutes.splash) &&
        !from.startsWith(AppRoutes.onboarding);
    return isSafeTarget ? from : AppRoutes.home;
  }
  if (!onboarded && location != AppRoutes.onboarding) {
    return AppRoutes.onboarding;
  }
  return null;
}

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
  );
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: StateView(
          icon: Icons.explore_off_outlined,
          title: "This page doesn't exist",
          message:
              'The address may be mistyped or the page may have moved. '
              "Head back to the J'ealth home screen to continue.",
          actions: [
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Return Home'),
            ),
          ],
        ),
      ),
    );
  }
}
