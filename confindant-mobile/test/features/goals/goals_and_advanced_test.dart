import 'package:confindant/features/analytics/models/advanced_analytics_models.dart';
import 'package:confindant/features/analytics/presentation/view_models/advanced_analytics_view_model.dart';
import 'package:confindant/features/goals/presentation/view_models/goals_view_model.dart';
import 'package:confindant/features/goals/presentation/view_models/habit_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('goals CRUD and contribution update works', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final vm = container.read(goalsViewModelProvider.notifier);
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

    vm.editGoal(added.id, name: 'New Laptop Pro');
    final afterEdit = container
        .read(goalsViewModelProvider)
        .firstWhere((g) => g.id == added.id);
    expect(afterEdit.name, 'New Laptop Pro');

    await vm.deleteGoal(added.id);
    expect(container.read(goalsViewModelProvider).length, initialCount);
  });

  test('habit progress increment and reset works', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

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
    final container = ProviderContainer();
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
      ExportRequest(format: ExportFormat.csv, filter: filter),
    );
    final result = container.read(exportProvider).value;
    expect(result?.success, isTrue);
    expect(result?.fileName.endsWith('.csv'), isTrue);
  });
}
