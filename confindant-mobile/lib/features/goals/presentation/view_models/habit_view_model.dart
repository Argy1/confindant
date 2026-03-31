import 'package:confindant/features/goals/data/goals_data_source.dart';
import 'package:confindant/features/goals/models/goals_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final habitViewModelProvider =
    StateNotifierProvider<HabitViewModel, List<HabitChallenge>>((ref) {
      final dataSource = ref.watch(goalsDataSourceProvider);
      final initial = dataSource is MockGoalsDataSource
          ? dataSource.seedData.habits
          : const <HabitChallenge>[];
      return HabitViewModel(dataSource, initialHabits: initial);
    });

final habitStreakProvider = StateProvider<HabitStreak>((ref) {
  final dataSource = ref.watch(goalsDataSourceProvider);
  if (dataSource is MockGoalsDataSource) {
    return dataSource.seedData.streak;
  }
  return const HabitStreak(
    currentStreak: 0,
    longestStreak: 0,
    lastUpdatedLabel: 'Updated today',
    badgeTitle: 'Consistency Starter',
  );
});

final habitReminderTextProvider = Provider<String>((ref) {
  final habits = ref.watch(habitViewModelProvider);
  final active = habits.where((h) => h.active).toList();
  if (active.isEmpty) return 'No active habits this week.';
  final pending = active.where((h) => !h.completed).length;
  if (pending == 0) return 'All habits completed this period. Great job!';
  return '$pending habit challenge(s) still pending this week.';
});

class HabitViewModel extends StateNotifier<List<HabitChallenge>> {
  HabitViewModel(
    this._dataSource, {
    List<HabitChallenge> initialHabits = const [],
  }) : super(initialHabits) {
    if (initialHabits.isEmpty) {
      _load();
    }
  }

  final GoalsDataSource _dataSource;

  Future<void> _load() async {
    final seed = await _dataSource.fetch();
    state = seed.habits;
  }

  Future<void> incrementProgress(String id) async {
    final updated = await _dataSource.incrementHabit(id);
    state = [
      for (final h in state)
        if (h.id == id) updated else h,
    ];
  }

  Future<void> resetProgress(String id) async {
    final updated = await _dataSource.resetHabit(id);
    state = [
      for (final h in state)
        if (h.id == id) updated else h,
    ];
  }

  void toggleActive(String id, bool value) {
    state = [
      for (final h in state)
        if (h.id == id) h.copyWith(active: value) else h,
    ];
  }
}
