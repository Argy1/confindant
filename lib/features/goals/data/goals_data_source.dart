import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:confindant/core/network/dto_utils.dart';
import 'package:confindant/features/goals/models/goals_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalsSeedData {
  const GoalsSeedData({
    required this.goals,
    required this.habits,
    required this.streak,
  });

  final List<GoalData> goals;
  final List<HabitChallenge> habits;
  final HabitStreak streak;
}

abstract class GoalsDataSource {
  Future<GoalsSeedData> fetch();
  Future<GoalData> createGoal({
    required String name,
    required double targetAmount,
    required String targetDateLabel,
    required String linkedWallet,
  });
  Future<void> deleteGoal(String id);
  Future<GoalData> addContribution(String id, double amount, {String? note});
  Future<HabitChallenge> incrementHabit(String id);
  Future<HabitChallenge> resetHabit(String id);
}

class MockGoalsDataSource implements GoalsDataSource {
  const MockGoalsDataSource();

  GoalsSeedData get seedData => const GoalsSeedData(
    goals: [
      GoalData(
        id: 'goal_1',
        name: 'Emergency Fund',
        targetAmount: 15000000,
        currentAmount: 5250000,
        targetDateLabel: 'Dec 2026',
        linkedWallet: 'Main Wallet',
        contributions: [
          GoalContribution(dateLabel: 'Mar 08', amount: 350000, note: 'Top up'),
        ],
      ),
    ],
    habits: [
      HabitChallenge(
        id: 'habit_1',
        title: 'No Coffee Outside',
        description: 'Skip buying coffee outside 3x this week.',
        targetCount: 3,
        currentCount: 2,
        frequency: HabitFrequency.weekly,
        active: true,
      ),
    ],
    streak: HabitStreak(
      currentStreak: 6,
      longestStreak: 13,
      lastUpdatedLabel: 'Updated today',
      badgeTitle: 'Consistency Starter',
    ),
  );

  @override
  Future<GoalsSeedData> fetch() async {
    return seedData;
  }

  @override
  Future<GoalData> createGoal({
    required String name,
    required double targetAmount,
    required String targetDateLabel,
    required String linkedWallet,
  }) async {
    return GoalData(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0,
      targetDateLabel: targetDateLabel,
      linkedWallet: linkedWallet,
      contributions: const [],
    );
  }

  @override
  Future<void> deleteGoal(String id) async {}

  @override
  Future<GoalData> addContribution(
    String id,
    double amount, {
    String? note,
  }) async {
    final seed = await fetch();
    final goal = seed.goals.firstWhere(
      (g) => g.id == id,
      orElse: () => GoalData(
        id: id,
        name: 'Goal',
        targetAmount: amount * 2,
        currentAmount: 0,
        targetDateLabel: 'Dec 2026',
        linkedWallet: 'Main Wallet',
        contributions: const [],
      ),
    );
    return goal.copyWith(
      currentAmount: goal.currentAmount + amount,
      contributions: [
        GoalContribution(
          dateLabel: DateTime.now().toString().substring(5, 10),
          amount: amount,
          note: note,
        ),
        ...goal.contributions,
      ],
    );
  }

  @override
  Future<HabitChallenge> incrementHabit(String id) async {
    final seed = await fetch();
    final habit = seed.habits.firstWhere(
      (h) => h.id == id,
      orElse: () => seed.habits.first,
    );
    return habit.copyWith(currentCount: habit.currentCount + 1);
  }

  @override
  Future<HabitChallenge> resetHabit(String id) async {
    final seed = await fetch();
    final habit = seed.habits.firstWhere(
      (h) => h.id == id,
      orElse: () => seed.habits.first,
    );
    return habit.copyWith(currentCount: 0);
  }
}

class ApiGoalsDataSource implements GoalsDataSource {
  const ApiGoalsDataSource(this._api);

  final BackendApiService _api;

  @override
  Future<GoalsSeedData> fetch() async {
    final goalsRaw = await _api.goals();
    final habitsRaw = await _api.habits();

    final goals = goalsRaw.map(_goalFromMap).toList();
    final habits = habitsRaw.map(_habitFromMap).toList();

    return GoalsSeedData(
      goals: goals,
      habits: habits,
      streak: HabitStreak(
        currentStreak: habits.where((h) => h.completed).length,
        longestStreak: habits.where((h) => h.completed).length,
        lastUpdatedLabel: 'Updated today',
        badgeTitle: habits.where((h) => h.completed).isEmpty
            ? 'Consistency Starter'
            : 'Consistency Builder',
      ),
    );
  }

  @override
  Future<GoalData> createGoal({
    required String name,
    required double targetAmount,
    required String targetDateLabel,
    required String linkedWallet,
  }) async {
    final raw = await _api.createGoal({
      'name': name,
      'target_amount': targetAmount,
      'target_date_label': targetDateLabel,
      'linked_wallet': linkedWallet,
    });
    return _goalFromMap(raw);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _api.deleteGoal(id);
  }

  @override
  Future<GoalData> addContribution(
    String id,
    double amount, {
    String? note,
  }) async {
    final raw = await _api.addGoalContribution(id, {
      'amount': amount,
      'note': note,
    });
    return _goalFromMap(raw);
  }

  @override
  Future<HabitChallenge> incrementHabit(String id) async {
    return _habitFromMap(await _api.incrementHabit(id));
  }

  @override
  Future<HabitChallenge> resetHabit(String id) async {
    return _habitFromMap(await _api.resetHabit(id));
  }

  GoalData _goalFromMap(Map<String, dynamic> m) {
    final contributionsRaw = (m['contributions'] as List? ?? const []);
    return GoalData(
      id: normalizeId(m),
      name: m['name']?.toString() ?? 'Goal',
      targetAmount: asDouble(m['target_amount']),
      currentAmount: asDouble(m['current_amount']),
      targetDateLabel: m['target_date_label']?.toString() ?? 'Dec 2026',
      linkedWallet: m['linked_wallet']?.toString() ?? 'Main Wallet',
      contributions: contributionsRaw.whereType<Map>().map((item) {
        final c = Map<String, dynamic>.from(item);
        return GoalContribution(
          dateLabel: c['date_label']?.toString() ?? '-',
          amount: asDouble(c['amount']),
          note: c['note']?.toString(),
        );
      }).toList(),
    );
  }

  HabitChallenge _habitFromMap(Map<String, dynamic> m) {
    final frequency = (m['frequency']?.toString() ?? 'weekly') == 'daily'
        ? HabitFrequency.daily
        : HabitFrequency.weekly;
    return HabitChallenge(
      id: normalizeId(m),
      title: m['title']?.toString() ?? 'Habit',
      description: m['description']?.toString() ?? '',
      targetCount: asInt(m['target_count'], fallback: 1),
      currentCount: asInt(m['current_count']),
      frequency: frequency,
      active: m['active'] == true,
    );
  }
}

final goalsDataSourceProvider = Provider<GoalsDataSource>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth.status.name != 'authenticated') {
    return const MockGoalsDataSource();
  }
  return ApiGoalsDataSource(ref.watch(backendApiServiceProvider));
});
