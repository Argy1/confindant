import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/core/auth/auth_state.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/analytics/analytics_export_page.dart';
import 'package:confindant/features/analytics/analytics_filter_page.dart';
import 'package:confindant/features/analytics/analytics_page.dart';
import 'package:confindant/features/auth/login_page.dart';
import 'package:confindant/features/auth/register_page.dart';
import 'package:confindant/features/category/manage_category_alt_page.dart';
import 'package:confindant/features/category/manage_category_page.dart';
import 'package:confindant/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:confindant/features/goals/presentation/pages/goals_page.dart';
import 'package:confindant/features/home/home_page.dart';
import 'package:confindant/features/onboarding/onboarding_page.dart';
import 'package:confindant/features/profile/about_page.dart';
import 'package:confindant/features/profile/change_password_page.dart';
import 'package:confindant/features/profile/help_center_page.dart';
import 'package:confindant/features/profile/notifications_page.dart';
import 'package:confindant/features/profile/personal_info_page.dart';
import 'package:confindant/features/profile/profile_page.dart';
import 'package:confindant/features/scan/scan_page.dart';
import 'package:confindant/features/scan/scan_receipt_page.dart';
import 'package:confindant/features/shell/main_shell_page.dart';
import 'package:confindant/features/splash/splash_page.dart';
import 'package:confindant/features/wallet/add_wallet_page.dart';
import 'package:confindant/features/wallet/wallet_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, _) {
    refresh.value++;
  });

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refresh,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.analytics,
                builder: (context, state) => const AnalyticsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.wallet,
                builder: (context, state) => const WalletPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.addWallet,
        builder: (context, state) => const AddWalletPage(),
      ),
      GoRoute(
        path: RoutePaths.manageCategory,
        builder: (context, state) => const ManageCategoryPage(),
      ),
      GoRoute(
        path: RoutePaths.manageCategoryAlt,
        builder: (context, state) => const ManageCategoryAltPage(),
      ),
      GoRoute(
        path: RoutePaths.manageCategoryLegacy,
        builder: (context, state) => const ManageCategoryAltPage(),
      ),
      GoRoute(
        path: RoutePaths.scan,
        builder: (context, state) => const ScanPage(),
      ),
      GoRoute(
        path: RoutePaths.scanReceipt,
        builder: (context, state) =>
            ScanReceiptPage(initialImagePath: state.extra?.toString()),
      ),
      GoRoute(
        path: RoutePaths.profilePersonalInfo,
        builder: (context, state) => const PersonalInfoPage(),
      ),
      GoRoute(
        path: RoutePaths.profileNotifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: RoutePaths.profileChangePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: RoutePaths.profileHelpCenter,
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: RoutePaths.profileAbout,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: RoutePaths.goals,
        builder: (context, state) => const GoalsPage(),
      ),
      GoRoute(
        path: RoutePaths.goalsDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return GoalDetailPage(goalId: id);
        },
      ),
      GoRoute(
        path: RoutePaths.analyticsFilter,
        builder: (context, state) => const AnalyticsFilterPage(),
      ),
      GoRoute(
        path: RoutePaths.analyticsExport,
        builder: (context, state) => const AnalyticsExportPage(),
      ),
    ],
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final path = state.uri.path;
      final isAuthRoute =
          path == RoutePaths.login || path == RoutePaths.register;
      final isBootFlow =
          path == RoutePaths.splash ||
          path == RoutePaths.onboarding ||
          isAuthRoute;

      if (auth.status == AuthStatus.unknown) {
        return path == RoutePaths.splash ? null : RoutePaths.splash;
      }

      if (auth.status == AuthStatus.unauthenticated && !isBootFlow) {
        return RoutePaths.login;
      }

      if (auth.status == AuthStatus.authenticated && isAuthRoute) {
        return RoutePaths.home;
      }

      return null;
    },
  );
});
