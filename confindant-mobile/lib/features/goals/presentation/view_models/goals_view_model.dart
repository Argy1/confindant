import 'package:confindant/features/goals/data/goals_data_source.dart';
import 'package:confindant/features/goals/models/goals_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goalsViewModelProvider =
    StateNotifierProvider<GoalsViewModel, List<GoalData>>((ref) {
      final dataSource = ref.watch(goalsDataSourceProvider);
      return GoalsViewModel(dataSource);
    });

class GoalsViewModel extends StateNotifier<List<GoalData>> {
  GoalsViewModel(this._dataSource) : super(const []) {
    _load();
  }

  final GoalsDataSource _dataSource;

  Future<void> _load() async {
    try {
      final seed = await _dataSource.fetch();
      state = seed.goals;
    } catch (_) {
      state = const [];
    }
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    required String targetDateLabel,
    required String linkedWallet,
    bool autoTopupEnabled = false,
    double autoTopupPercent = 0,
  }) async {
    final created = await _dataSource.createGoal(
      name: name,
      targetAmount: targetAmount,
      targetDateLabel: targetDateLabel,
      linkedWallet: linkedWallet,
      autoTopupEnabled: autoTopupEnabled,
      autoTopupPercent: autoTopupPercent,
    );
    state = [...state, created];
  }

  Future<void> editGoal(
    String id, {
    String? name,
    double? targetAmount,
    String? targetDateLabel,
    String? linkedWallet,
    bool? autoTopupEnabled,
    double? autoTopupPercent,
  }) async {
    final updated = await _dataSource.updateGoal(
      id: id,
      name: name,
      targetAmount: targetAmount,
      targetDateLabel: targetDateLabel,
      linkedWallet: linkedWallet,
      autoTopupEnabled: autoTopupEnabled,
      autoTopupPercent: autoTopupPercent,
    );
    state = [
      for (final g in state)
        if (g.id == id) updated else g,
    ];
  }

  Future<void> deleteGoal(String id) async {
    await _dataSource.deleteGoal(id);
    state = state.where((g) => g.id != id).toList();
  }

  Future<void> addContribution(String id, double amount, {String? note}) async {
    final updated = await _dataSource.addContribution(id, amount, note: note);
    state = [
      for (final g in state)
        if (g.id == id) updated else g,
    ];
  }
}

final selectedGoalIdProvider = StateProvider<String?>((ref) => null);

final selectedGoalProvider = Provider<GoalData?>((ref) {
  final id = ref.watch(selectedGoalIdProvider);
  final goals = ref.watch(goalsViewModelProvider);
  if (id == null) return null;
  for (final g in goals) {
    if (g.id == id) return g;
  }
  return null;
});
