import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/goals/models/goals_models.dart';
import 'package:confindant/features/goals/presentation/view_models/goals_view_model.dart';
import 'package:confindant/features/home/presentation/widgets/home_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsViewModelProvider);
    GoalData? goal;
    for (final g in goals) {
      if (g.id == goalId) {
        goal = g;
        break;
      }
    }
    if (goal == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Goal not found')),
      );
    }

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
                    Expanded(
                      child: Text(
                        goal.name,
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Linked wallet: ${goal.linkedWallet}',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        'Target date: ${goal.targetDateLabel}',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${formatHomeRupiah(goal.currentAmount)} / ${formatHomeRupiah(goal.targetAmount)}',
                        style: AppTextStyles.sectionTitle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contribution History',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 10),
                      for (final c in goal.contributions) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${c.dateLabel} ${c.note == null ? '' : '• ${c.note}'}',
                                style: AppTextStyles.caption,
                              ),
                            ),
                            Text(
                              formatHomeRupiah(c.amount),
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.accentAction,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (c != goal.contributions.last)
                          const Divider(height: 12),
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
}
