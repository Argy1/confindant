enum HabitFrequency { daily, weekly }

class GoalContribution {
  const GoalContribution({
    required this.dateLabel,
    required this.amount,
    this.note,
  });

  final String dateLabel;
  final double amount;
  final String? note;
}

class GoalData {
  const GoalData({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDateLabel,
    required this.linkedWallet,
    required this.contributions,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String targetDateLabel;
  final String linkedWallet;
  final List<GoalContribution> contributions;

  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0, 1);
  }

  GoalData copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? targetDateLabel,
    String? linkedWallet,
    List<GoalContribution>? contributions,
  }) {
    return GoalData(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDateLabel: targetDateLabel ?? this.targetDateLabel,
      linkedWallet: linkedWallet ?? this.linkedWallet,
      contributions: contributions ?? this.contributions,
    );
  }
}

class HabitChallenge {
  const HabitChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCount,
    required this.currentCount,
    required this.frequency,
    required this.active,
  });

  final String id;
  final String title;
  final String description;
  final int targetCount;
  final int currentCount;
  final HabitFrequency frequency;
  final bool active;

  bool get completed => currentCount >= targetCount;

  HabitChallenge copyWith({
    String? id,
    String? title,
    String? description,
    int? targetCount,
    int? currentCount,
    HabitFrequency? frequency,
    bool? active,
  }) {
    return HabitChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      frequency: frequency ?? this.frequency,
      active: active ?? this.active,
    );
  }
}

class HabitStreak {
  const HabitStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastUpdatedLabel,
    required this.badgeTitle,
  });

  final int currentStreak;
  final int longestStreak;
  final String lastUpdatedLabel;
  final String badgeTitle;
}
