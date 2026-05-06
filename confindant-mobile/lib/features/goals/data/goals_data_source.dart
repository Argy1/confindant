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
    bool autoTopupEnabled = false,
    double autoTopupPercent = 0,
  });
  Future<GoalData> updateGoal({
    required String id,
    String? name,
    double? targetAmount,
    String? targetDateLabel,
    String? linkedWallet,
    bool? autoTopupEnabled,
    double? autoTopupPercent,
  });
  Future<void> deleteGoal(String id);
  Future<GoalData> addContribution(String id, double amount, {String? note});
  Future<HabitChallenge> incrementHabit(String id);
  Future<HabitChallenge> resetHabit(String id);
  Future<HabitChallenge> updateHabitActive(String id, bool active);
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
        autoTopupEnabled: false,
        autoTopupPercent: 0,
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
    bool autoTopupEnabled = false,
    double autoTopupPercent = 0,
  }) async {
    return GoalData(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0,
      targetDateLabel: targetDateLabel,
      linkedWallet: linkedWallet,
      autoTopupEnabled: autoTopupEnabled,
      autoTopupPercent: autoTopupPercent,
      contributions: const [],
    );
  }

  @override
  Future<void> deleteGoal(String id) async {}

  @override
  Future<GoalData> updateGoal({
    required String id,
    String? name,
    double? targetAmount,
    String? targetDateLabel,
    String? linkedWallet,
    bool? autoTopupEnabled,
    double? autoTopupPercent,
  }) async {
    final seed = await fetch();
    final existing = seed.goals.where((g) => g.id == id);
    if (existing.isNotEmpty) {
      return existing.first.copyWith(
        name: name,
        targetAmount: targetAmount,
        targetDateLabel: targetDateLabel,
        linkedWallet: linkedWallet,
        autoTopupEnabled: autoTopupEnabled,
        autoTopupPercent: autoTopupPercent,
      );
    }

    return GoalData(
      id: id,
      name: name ?? 'Goal',
      targetAmount: targetAmount ?? 0,
      currentAmount: 0,
      targetDateLabel: targetDateLabel ?? 'Dec 2026',
      linkedWallet: linkedWallet ?? 'Main Wallet',
      autoTopupEnabled: autoTopupEnabled ?? false,
      autoTopupPercent: autoTopupPercent ?? 0,
      contributions: const [],
    );
  }

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
        autoTopupEnabled: false,
        autoTopupPercent: 0,
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

  @override
  Future<HabitChallenge> updateHabitActive(String id, bool active) async {
    final seed = await fetch();
    final habit = seed.habits.firstWhere(
      (h) => h.id == id,
      orElse: () => seed.habits.first,
    );
    return habit.copyWith(active: active);
  }
}

class ApiGoalsDataSource implements GoalsDataSource {
  const ApiGoalsDataSource(this._api);

  final BackendApiService _api;

  @override
  Future<GoalsSeedData> fetch() async {
    final goalsRaw = await _api.goals();
    final habitsBundle = await _api.habitsBundle();
    final habitsRaw = (habitsBundle['habits'] as List<Map<String, dynamic>>? ?? const []);
    final meta = Map<String, dynamic>.from(
      habitsBundle['meta'] as Map? ?? const {},
    );
    final streakMap = Map<String, dynamic>.from(
      meta['streak'] as Map? ?? const {},
    );

    final goals = goalsRaw.map(_goalFromMap).toList();
    final habits = habitsRaw.map(_habitFromMap).toList();

    return GoalsSeedData(
      goals: goals,
      habits: habits,
      streak: HabitStreak(
        currentStreak: asInt(streakMap['current_streak']),
        longestStreak: asInt(streakMap['longest_streak']),
        lastUpdatedLabel:
            streakMap['last_updated_label']?.toString() ?? 'Updated today',
        badgeTitle:
            streakMap['badge_title']?.toString() ?? 'Consistency Starter',
      ),
    );
  }

  @override
  Future<GoalData> createGoal({
    required String name,
    required double targetAmount,
    required String targetDateLabel,
    required String linkedWallet,
    bool autoTopupEnabled = false,
    double autoTopupPercent = 0,
  }) async {
    final raw = await _api.createGoal({
      'name': name,
      'target_amount': targetAmount,
      'target_date_label': targetDateLabel,
      'linked_wallet': linkedWallet,
      'auto_topup_enabled': autoTopupEnabled,
      'auto_topup_percent': autoTopupPercent,
    });
    return _goalFromMap(raw);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _api.deleteGoal(id);
  }

  @override
  Future<GoalData> updateGoal({
    required String id,
    String? name,
    double? targetAmount,
    String? targetDateLabel,
    String? linkedWallet,
    bool? autoTopupEnabled,
    double? autoTopupPercent,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (targetAmount != null) body['target_amount'] = targetAmount;
    if (targetDateLabel != null) body['target_date_label'] = targetDateLabel;
    if (linkedWallet != null) body['linked_wallet'] = linkedWallet;
    if (autoTopupEnabled != null) body['auto_topup_enabled'] = autoTopupEnabled;
    if (autoTopupPercent != null) body['auto_topup_percent'] = autoTopupPercent;
    final raw = await _api.updateGoal(id, body);
    return _goalFromMap(raw);
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

  @override
  Future<HabitChallenge> updateHabitActive(String id, bool active) async {
    return _habitFromMap(await _api.updateHabit(id, {'active': active}));
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
      autoTopupEnabled: m['auto_topup_enabled'] == true,
      autoTopupPercent: asDouble(m['auto_topup_percent']),
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
  return ApiGoalsDataSource(ref.watch(backendApiServiceProvider));
});
