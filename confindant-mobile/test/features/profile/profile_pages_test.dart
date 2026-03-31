import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/widgets/app_primary_button.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/profile/about_page.dart';
import 'package:confindant/features/profile/change_password_page.dart';
import 'package:confindant/features/profile/help_center_page.dart';
import 'package:confindant/features/profile/notifications_page.dart';
import 'package:confindant/features/profile/personal_info_page.dart';
import 'package:confindant/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:confindant/features/profile/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  GoRouter buildProfileRouter() {
    return GoRouter(
      initialLocation: RoutePaths.profile,
      routes: [
        GoRoute(
          path: RoutePaths.profile,
          builder: (context, state) => const ProfilePage(),
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
          path: RoutePaths.login,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Login Page'))),
        ),
      ],
    );
  }

  testWidgets('profile menu taps open all detail pages', (tester) async {
    final container = ProviderContainer(
      overrides: [isAuthenticatedProvider.overrideWith((ref) => true)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: buildProfileRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Personal Information'));
    await tester.pumpAndSettle();
    expect(find.text('Manage your account identity'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Control reminders and alerts'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();
    expect(find.text('Keep your account secure'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Help Center'));
    await tester.pumpAndSettle();
    expect(find.text('Find answers and support'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('About Confindant'));
    await tester.pumpAndSettle();
    expect(find.text('App info and legal references'), findsOneWidget);
  });

  testWidgets('logout shows sheet then redirects and clears auth', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [isAuthenticatedProvider.overrideWith((ref) => true)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: buildProfileRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Logout'));
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(
      find.text('Are you sure you want to logout from Confindant?'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(container.read(isAuthenticatedProvider), isFalse);
    expect(find.text('Login Page'), findsOneWidget);
  });

  testWidgets('notifications toggles update provider state', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final before = container.read(profileSettingsProvider).notificationSettings;
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    final after = container.read(profileSettingsProvider).notificationSettings;
    expect(before.pushEnabled != after.pushEnabled, isTrue);
  });

  testWidgets('change password strict validation enables submit', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ChangePasswordPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Update Password'));
    await tester.pumpAndSettle();
    expect(find.text('Password updated (mock).'), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), 'CurrentPass1!');
    await tester.enterText(find.byType(TextField).at(1), 'NewStrong1!');
    await tester.enterText(find.byType(TextField).at(2), 'NewStrong1!');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Update Password'));
    await tester.pumpAndSettle();
    expect(find.text('Password updated (mock).'), findsOneWidget);
  });

  testWidgets('help center and about render main sections', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HelpCenterPage())),
    );
    await tester.pumpAndSettle();
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Contact Support'), findsOneWidget);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AboutPage())),
    );
    await tester.pumpAndSettle();
    expect(find.text('App Identity'), findsOneWidget);
    expect(find.text('Legal & Policy'), findsOneWidget);
  });
}
