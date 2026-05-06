import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/features/scan/scan_page.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('scan page shows Input Manual and navigates without image path', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: RoutePaths.scan,
      routes: [
        GoRoute(
          path: RoutePaths.scan,
          builder: (context, state) => const ScanPage(),
        ),
        GoRoute(
          path: RoutePaths.scanReceipt,
          builder: (context, state) => Scaffold(
            body: Text(state.extra == null ? 'manual-mode' : 'image-mode'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Input Manual'), findsOneWidget);

    await tester.tap(find.text('Input Manual'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 250));

    expect(router.state.uri.path, RoutePaths.scanReceipt);
    expect(router.state.extra, isNull);
  });
}
