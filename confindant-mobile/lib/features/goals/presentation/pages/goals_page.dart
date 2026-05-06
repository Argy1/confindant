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
                    const LanguageSwitcherButton(
                      iconColor: AppColors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
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
    final autoTopupPercent = TextEditingController(text: '10');
    var autoTopupEnabled = false;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: autoTopupEnabled,
                    title: const Text('Auto-topup from income'),
                    onChanged: (value) => setDialogState(() => autoTopupEnabled = value),
                  ),
                  TextField(
                    controller: autoTopupPercent,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: autoTopupEnabled,
                    decoration: const InputDecoration(labelText: 'Auto-topup percent (%)'),
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
                    final percent = double.tryParse(autoTopupPercent.text) ?? 0;
                    if (name.text.trim().isEmpty || parsed <= 0) return;
                    ref
                        .read(goalsViewModelProvider.notifier)
                        .addGoal(
                          name: name.text.trim(),
                          targetAmount: parsed,
                          targetDateLabel: 'Dec 2026',
                          linkedWallet: 'Main Wallet',
                          autoTopupEnabled: autoTopupEnabled,
                          autoTopupPercent: autoTopupEnabled ? percent.clamp(0, 100) : 0,
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    autoTopupPercent.dispose();
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
                  if (v == 'edit') {
                    _showEditGoalDialog(context, ref, goal);
                    return;
                  }
                  if (v == 'delete') {
                    ref
                        .read(goalsViewModelProvider.notifier)
                        .deleteGoal(goal.id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
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
          if (goal.autoTopupEnabled) ...[
            const SizedBox(height: 6),
            Text(
              'Auto-topup: ${goal.autoTopupPercent.toStringAsFixed(0)}% from each income',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accentAction,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
        Switch(
          value: challenge.active,
          onChanged: (value) async {
            await ref.read(habitViewModelProvider.notifier).toggleActive(
              challenge.id,
              value,
            );
          },
        ),
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
          onPressed: challenge.active
              ? () {
            ref
                .read(habitViewModelProvider.notifier)
                .incrementProgress(challenge.id);
          }
              : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: AppColors.accentAction,
        ),
      ],
    );
  }
}

Future<void> _showEditGoalDialog(
  BuildContext context,
  WidgetRef ref,
  GoalData goal,
) async {
  final nameController = TextEditingController(text: goal.name);
  final targetController = TextEditingController(
    text: goal.targetAmount.toStringAsFixed(0),
  );
  final autoTopupPercentController = TextEditingController(
    text: goal.autoTopupPercent.toStringAsFixed(0),
  );
  var autoTopupEnabled = goal.autoTopupEnabled;
  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocalState) {
          return AlertDialog(
            title: const Text('Edit Goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Goal name'),
                ),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Target amount'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: autoTopupEnabled,
                  title: const Text('Auto-topup from income'),
                  onChanged: (value) => setLocalState(() => autoTopupEnabled = value),
                ),
                TextField(
                  controller: autoTopupPercentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: autoTopupEnabled,
                  decoration: const InputDecoration(labelText: 'Auto-topup percent (%)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final target = double.tryParse(targetController.text.trim());
                        final autoTopupPercent =
                            double.tryParse(autoTopupPercentController.text.trim()) ?? 0;
                        if (nameController.text.trim().isEmpty ||
                            target == null ||
                            target <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid goal input.')),
                          );
                          return;
                        }
                        setLocalState(() => saving = true);
                        try {
                          await ref
                              .read(goalsViewModelProvider.notifier)
                              .editGoal(
                                goal.id,
                                name: nameController.text.trim(),
                                targetAmount: target,
                                autoTopupEnabled: autoTopupEnabled,
                                autoTopupPercent: autoTopupEnabled
                                    ? autoTopupPercent.clamp(0, 100)
                                    : 0,
                              );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update goal.')),
                          );
                        } finally {
                          if (ctx.mounted) {
                            setLocalState(() => saving = false);
                          }
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ],
          );
        },
      );
    },
  );

  nameController.dispose();
  targetController.dispose();
  autoTopupPercentController.dispose();
}
