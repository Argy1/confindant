import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/goals/models/goals_models.dart';
import 'package:confindant/features/goals/presentation/view_models/goals_view_model.dart';
import 'package:confindant/features/goals/presentation/view_models/habit_view_model.dart';
import 'package:confindant/features/home/presentation/widgets/home_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsViewModelProvider);
    final habits = ref.watch(habitViewModelProvider);
    final streak = ref.watch(habitStreakProvider);
    final reminder = ref.watch(habitReminderTextProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.white,
                    ),
                    Text(
                      'Savings Goals',
                      style: AppTextStyles.screenTitle.copyWith(
                        color: AppColors.white,
                        fontSize: 26,
                      ),
                    ),
                    const Spacer(),
                    AppIconButtonCircle(
                      icon: Icons.add_rounded,
                      size: 34,
                      backgroundColor: AppColors.white,
                      iconColor: AppColors.accentAction,
                      onPressed: () => _showCreateGoalDialog(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Habit Streak', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 8),
                      Text(
                        '${streak.currentStreak} days streak • ${streak.badgeTitle}',
                        style: AppTextStyles.body.copyWith(fontSize: 14),
                      ),
                      Text(
                        streak.lastUpdatedLabel,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      Text(reminder, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...goals.map((goal) => _GoalCard(goal: goal)),
                const SizedBox(height: AppSpacing.md),
                AppCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habit Challenges',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final h in habits) ...[
                        _HabitRow(challenge: h),
                        if (h != habits.last) const Divider(height: 14),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final target = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Goal name'),
              ),
              TextField(
                controller: target,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = double.tryParse(target.text) ?? 0;
                if (name.text.trim().isEmpty || parsed <= 0) return;
                ref
                    .read(goalsViewModelProvider.notifier)
                    .addGoal(
                      name: name.text.trim(),
                      targetAmount: parsed,
                      targetDateLabel: 'Dec 2026',
                      linkedWallet: 'Main Wallet',
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final GoalData goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklySuggestion =
        ((goal.targetAmount - goal.currentAmount).clamp(0, goal.targetAmount) /
                20)
            .roundToDouble();
    return AppCardContainer(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') {
                    ref
                        .read(goalsViewModelProvider.notifier)
                        .deleteGoal(goal.id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          Text(
            '${formatHomeRupiah(goal.currentAmount)} / ${formatHomeRupiah(goal.targetAmount)}',
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentAction,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Milestone: ${(goal.progress * 100).toStringAsFixed(0)}% • Weekly suggestion ${formatHomeRupiah(weeklySuggestion)}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: 'View Detail',
                  onPressed: () => context.push(
                    RoutePaths.goalsDetail.replaceFirst(':id', goal.id),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppPrimaryButton(
                  label: 'Top-up',
                  onPressed: () {
                    ref
                        .read(goalsViewModelProvider.notifier)
                        .addContribution(goal.id, 250000, note: 'Quick top-up');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends ConsumerWidget {
  const _HabitRow({required this.challenge});

  final HabitChallenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challenge.title,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${challenge.currentCount}/${challenge.targetCount} • ${challenge.frequency.name}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            ref
                .read(habitViewModelProvider.notifier)
                .incrementProgress(challenge.id);
          },
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: AppColors.accentAction,
        ),
      ],
    );
  }
}
