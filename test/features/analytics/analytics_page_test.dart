import 'package:confindant/features/analytics/analytics_page.dart';
import 'package:confindant/features/analytics/data/analytics_data_source.dart';
import 'package:confindant/features/goals/data/goals_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAnalyticsPage(
    WidgetTester tester, {
    AnalyticsDataSource? dataSource,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsDataSourceProvider.overrideWithValue(
            dataSource ?? const MockAnalyticsDataSource(),
          ),
          goalsDataSourceProvider.overrideWithValue(
            const MockGoalsDataSource(),
          ),
        ],
        child: const MaterialApp(home: AnalyticsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders loaded analytics state', (tester) async {
    await pumpAnalyticsPage(tester);

    expect(find.byKey(const ValueKey('analytics_loaded_view')), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Category Breakdown'), findsOneWidget);
  });

  testWidgets('renders empty analytics state', (tester) async {
    await pumpAnalyticsPage(
      tester,
      dataSource: const MockAnalyticsDataSource(mode: AnalyticsSeedMode.empty),
    );

    expect(find.byKey(const ValueKey('analytics_empty_view')), findsOneWidget);
    expect(find.textContaining('No analytics data yet'), findsOneWidget);
  });

  testWidgets('renders error analytics state and retry action', (tester) async {
    await pumpAnalyticsPage(
      tester,
      dataSource: const MockAnalyticsDataSource(mode: AnalyticsSeedMode.error),
    );

    expect(find.byKey(const ValueKey('analytics_error_view')), findsOneWidget);
    expect(
      find.text('Unable to load analytics data right now.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('switching period keeps analytics visible', (tester) async {
    await pumpAnalyticsPage(tester);

    await tester.tap(find.byKey(const ValueKey('analytics_period_weekly')));
    await tester.pumpAndSettle();

    expect(find.byType(AnalyticsPage), findsOneWidget);
  });
}
