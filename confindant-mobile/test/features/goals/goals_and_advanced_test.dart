import 'package:confindant/features/analytics/data/analytics_export_service.dart';
import 'package:confindant/features/analytics/models/advanced_analytics_models.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:confindant/features/analytics/presentation/view_models/advanced_analytics_view_model.dart';
import 'package:confindant/features/goals/data/goals_data_source.dart';
import 'package:confindant/features/goals/presentation/view_models/goals_view_model.dart';
import 'package:confindant/features/goals/presentation/view_models/habit_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeExportService extends AnalyticsExportService {
  @override
  Future<ExportResult> export(ExportRequest request) async {
    final ext = request.format == ExportFormat.csv ? 'csv' : 'pdf';
    return ExportResult(
      fileName: 'analytics_test.$ext',
      success: true,
      message: 'fake export',
    );
  }
}

void main() {
  test('goals CRUD and contribution update works', () async {
    final container = ProviderContainer(
      overrides: [
        analyticsExportServiceProvider.overrideWithValue(_FakeExportService()),
        goalsDataSourceProvider.overrideWithValue(const MockGoalsDataSource()),
      ],
    );
    addTearDown(container.dispose);

    final vm = container.read(goalsViewModelProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final initialCount = container.read(goalsViewModelProvider).length;

    await vm.addGoal(
      name: 'New Laptop',
      targetAmount: 15000000,
      targetDateLabel: 'Jan 2027',
      linkedWallet: 'Main Wallet',
    );
    expect(container.read(goalsViewModelProvider).length, initialCount + 1);

    final added = container.read(goalsViewModelProvider).last;
    await vm.addContribution(added.id, 500000, note: 'First top up');
    final afterContribution = container
        .read(goalsViewModelProvider)
        .firstWhere((g) => g.id == added.id);
    expect(afterContribution.currentAmount, greaterThan(0));
    expect(afterContribution.contributions.isNotEmpty, isTrue);

    await vm.editGoal(added.id, name: 'New Laptop Pro');
    final afterEdit = container
        .read(goalsViewModelProvider)
        .firstWhere((g) => g.id == added.id);
    expect(afterEdit.name, 'New Laptop Pro');

    await vm.deleteGoal(added.id);
    expect(container.read(goalsViewModelProvider).length, initialCount);
  });

  test('habit progress increment and reset works', () async {
    final container = ProviderContainer(
      overrides: [
        goalsDataSourceProvider.overrideWithValue(const MockGoalsDataSource()),
      ],
    );
    addTearDown(container.dispose);

    container.read(habitViewModelProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final habits = container.read(habitViewModelProvider);
    final first = habits.first;
    final vm = container.read(habitViewModelProvider.notifier);

    await vm.incrementProgress(first.id);
    final afterInc = container
        .read(habitViewModelProvider)
        .firstWhere((h) => h.id == first.id);
    expect(afterInc.currentCount, greaterThanOrEqualTo(first.currentCount));

    await vm.resetProgress(first.id);
    final afterReset = container
        .read(habitViewModelProvider)
        .firstWhere((h) => h.id == first.id);
    expect(afterReset.currentCount, 0);
  });

  test('advanced analytics filter and export works', () async {
    final container = ProviderContainer(
      overrides: [
        goalsDataSourceProvider.overrideWithValue(const MockGoalsDataSource()),
      ],
    );
    addTearDown(container.dispose);

    final vm = container.read(advancedAnalyticsProvider.notifier);
    vm.updateFilter(
      fromDateLabel: '2026-02-01',
      toDateLabel: '2026-02-28',
      wallet: 'Main Wallet',
      category: 'Food',
    );
    final filter = container.read(advancedAnalyticsProvider);
    expect(filter.wallet, 'Main Wallet');
    expect(filter.category, 'Food');

    final exportVm = container.read(exportProvider.notifier);
    await exportVm.export(
      ExportRequest(
        format: ExportFormat.csv,
        filter: filter,
        period: AnalyticsPeriod.monthly,
        data: const AnalyticsLoadedData(
          summary: AnalyticsSummaryData(
            totalIncome: 1000000,
            totalExpense: 500000,
            netSaving: 500000,
          ),
          categoryBreakdown: [AnalyticsCategorySlice(label: 'Food', amount: 500000, color: Color(0xFF000000))],
          incomeBreakdown: [
            AnalyticsCategorySlice(label: 'Salary', amount: 1000000, color: Color(0xFF00FF00)),
          ],
          trendPoints: [AnalyticsTrendPoint(label: 'Week 1', amount: 500000)],
          incomeTrendPoints: [AnalyticsTrendPoint(label: 'Week 1', amount: 1000000)],
          netFlowTrend: [AnalyticsTrendPoint(label: 'Week 1', amount: 500000)],
          budgetProgress: [
            AnalyticsBudgetItem(category: 'Food', used: 500000, limit: 1000000),
          ],
          budgetRecommendations: [],
          comparison: {
            'mode': 'monthOverMonth',
            'current_value': 500000,
            'previous_value': 400000,
            'delta_percent': 25.0,
          },
          anomaly: {
            'category': 'Food',
            'spike_percent': 10.0,
            'message': 'Food spending changed 10%',
          },
          insightText: 'Test insight',
        ),
      ),
    );
    final result = container.read(exportProvider).value;
    expect(result?.success, isTrue);
    expect(result?.fileName.endsWith('.csv'), isTrue);
  });
}
