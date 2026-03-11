import 'package:confindant/features/goals/data/goals_data_source.dart';
import 'package:confindant/features/home/data/home_data_source.dart';
import 'package:confindant/features/home/home_page.dart';
import 'package:confindant/features/home/models/home_models.dart';
import 'package:confindant/features/home/presentation/widgets/home_quick_actions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHomePage(
    WidgetTester tester, {
    HomeDataSource? dataSource,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDataSourceProvider.overrideWithValue(
            dataSource ?? const MockHomeDataSource(),
          ),
          goalsDataSourceProvider.overrideWithValue(
            const MockGoalsDataSource(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HomePage())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders loaded home state', (tester) async {
    await pumpHomePage(tester);

    expect(find.byKey(const ValueKey('home_loaded_view')), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Budget Snapshot'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);
  });

  testWidgets('renders empty home state', (tester) async {
    await pumpHomePage(
      tester,
      dataSource: const MockHomeDataSource(mode: HomeSeedMode.empty),
    );

    expect(find.byKey(const ValueKey('home_empty_view')), findsOneWidget);
    expect(find.textContaining('Belum ada transaksi'), findsOneWidget);
  });

  testWidgets('renders error home state', (tester) async {
    await pumpHomePage(
      tester,
      dataSource: const MockHomeDataSource(mode: HomeSeedMode.error),
    );

    expect(find.byKey(const ValueKey('home_error_view')), findsOneWidget);
    expect(find.text('Unable to load dashboard right now.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('quick action callback is triggered', (tester) async {
    HomeQuickActionType? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeQuickActionsCard(
            actions: const [
              HomeQuickAction(
                type: HomeQuickActionType.addExpense,
                label: 'Add Expense',
                icon: Icons.remove_circle_outline_rounded,
              ),
            ],
            onActionTap: (type) => tapped = type,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('home_quick_action_addExpense')),
    );
    await tester.pumpAndSettle();

    expect(tapped, HomeQuickActionType.addExpense);
  });

  testWidgets('recent transactions shows positive and negative amounts', (
    tester,
  ) async {
    await pumpHomePage(tester);

    expect(find.textContaining('- Rp'), findsWidgets);
    expect(find.textContaining('+ Rp'), findsWidgets);
  });
}
