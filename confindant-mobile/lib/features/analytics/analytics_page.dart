import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/utils/time_greeting.dart';
import 'package:confindant/features/analytics/models/advanced_analytics_models.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:confindant/features/analytics/presentation/view_models/advanced_analytics_view_model.dart';
import 'package:confindant/features/analytics/presentation/view_models/analytics_view_model.dart';
import 'package:confindant/features/analytics/presentation/widgets/widgets.dart';
import 'package:confindant/features/goals/presentation/view_models/goals_view_model.dart';
import 'package:confindant/features/home/presentation/widgets/home_formatters.dart';
import 'package:confindant/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum AnalyticsTrendMode { expenseOnly, netFlow }

final analyticsTrendModeProvider = StateProvider<AnalyticsTrendMode>((ref) {
  return AnalyticsTrendMode.expenseOnly;
});

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(analyticsViewModelProvider);
    final vm = ref.read(analyticsViewModelProvider.notifier);
    final profile = ref.watch(profileSettingsProvider).userData;
    final filter = ref.watch(advancedAnalyticsProvider);
    final comparison = ref.watch(periodComparisonProvider);
    final anomaly = ref.watch(anomalyInsightProvider);
    final trendMode = ref.watch(analyticsTrendModeProvider);
    final goals = ref.watch(goalsViewModelProvider);
    final goalsSavingImpact = goals.fold<double>(
      0,
      (sum, g) => sum + g.currentAmount,
    );
    // ignore: avoid_print

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.appBackground),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(31, 62, 31, 140),
          child: Column(
            children: [
              _AnalyticsTopRow(
                name: profile.fullName.isEmpty ? 'User' : profile.fullName,
                avatarPath: profile.avatarPath,
                onNotificationTap: () => context.push(RoutePaths.profileNotifications),
              ),
              const SizedBox(height: AppSpacing.lg),
              _AnalyticsFilterBar(
                filter: filter,
                onOpenFilter: () => context.push(RoutePaths.analyticsFilter),
                onExport: () => context.push(RoutePaths.analyticsExport),
              ),
              const SizedBox(height: AppSpacing.md),
              AnalyticsPeriodToggle(
                selected: state.period,
                onChanged: vm.setPeriod,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.uiState == AnalyticsUiState.loaded &&
                  state.data != null)
                _LoadedAnalyticsView(
                  state: state,
                  comparison: comparison,
                  anomaly: anomaly,
                  goalsSavingImpact: goalsSavingImpact,
                  trendMode: trendMode,
                  onTrendModeChanged: (mode) {
                    ref.read(analyticsTrendModeProvider.notifier).state = mode;
                  },
                ),
              if (state.uiState == AnalyticsUiState.empty)
                const _EmptyAnalyticsView(),
              if (state.uiState == AnalyticsUiState.error)
                _ErrorAnalyticsView(
                  message: state.errorMessage ?? l10n.analyticsUnableLoadData,
                  onRetry: vm.retry,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadedAnalyticsView extends StatelessWidget {
  const _LoadedAnalyticsView({
    required this.state,
    required this.comparison,
    required this.anomaly,
    required this.goalsSavingImpact,
    required this.trendMode,
    required this.onTrendModeChanged,
  });

  final AnalyticsScreenState state;
  final PeriodComparison comparison;
  final AnomalyInsight anomaly;
  final double goalsSavingImpact;
  final AnalyticsTrendMode trendMode;
  final ValueChanged<AnalyticsTrendMode> onTrendModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = state.data!;
    return Column(
      key: const ValueKey('analytics_loaded_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnalyticsSummaryCard(summary: data.summary),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: AnalyticsDonutBreakdownCard(
            slices: data.categoryBreakdown,
            title: l10n.analyticsExpenseBreakdown,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: AnalyticsDonutBreakdownCard(
            slices: data.incomeBreakdown,
            title: l10n.analyticsIncomeSources,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: _TrendModeToggle(
            trendMode: trendMode,
            onTrendModeChanged: onTrendModeChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: AnalyticsTrendCard(
            period: state.period,
            points: trendMode == AnalyticsTrendMode.netFlow
                ? data.netFlowTrend
                : data.trendPoints,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ComparisonCard(comparison: comparison),
        const SizedBox(height: AppSpacing.md),
        _AnomalyCard(anomaly: anomaly),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: AnalyticsBudgetProgressCard(items: data.budgetProgress),
        ),
        if (data.budgetRecommendations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: _BudgetRecommendationCard(items: data.budgetRecommendations),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: AnalyticsInsightCard(text: data.insightText),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: AppCardContainer(
            child: Text(
              'Saving goals impact: ${formatHomeRupiah(goalsSavingImpact)} has been allocated to active goals.',
              style: AppTextStyles.caption.copyWith(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetRecommendationCard extends StatelessWidget {
  const _BudgetRecommendationCard({required this.items});

  final List<BudgetRecommendationItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Budget Recommendations',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          ...items.take(3).map((item) {
            final delta = item.recommendedLimit - item.currentLimit;
            final deltaLabel = delta <= 0 ? 'Keep' : '+${formatHomeRupiah(delta)}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.category,
                            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          deltaLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: delta > 0 ? const Color(0xFFC10007) : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current ${formatHomeRupiah(item.currentLimit)} -> Recommended ${formatHomeRupiah(item.recommendedLimit)}',
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.reason,
                      style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (item.simulationChangePercent != null &&
                        item.simulationSavingImpact != null &&
                        item.simulationLimit != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Simulasi ${item.simulationChangePercent!.toStringAsFixed(0)}% -> limit ${formatHomeRupiah(item.simulationLimit!)} | dampak saving ${formatHomeRupiah(item.simulationSavingImpact!)}',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TrendModeToggle extends StatelessWidget {
  const _TrendModeToggle({
    required this.trendMode,
    required this.onTrendModeChanged,
  });

  final AnalyticsTrendMode trendMode;
  final ValueChanged<AnalyticsTrendMode> onTrendModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCardContainer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useVertical = constraints.maxWidth < 360;
          if (useVertical) {
            return Column(
              children: [
                AppSecondaryButton(
                  label: l10n.analyticsExpenseOnly,
                  backgroundColor: trendMode == AnalyticsTrendMode.expenseOnly
                      ? const Color(0xFFE0F6FF)
                      : Colors.transparent,
                  foregroundColor: AppColors.accentAction,
                  onPressed: () => onTrendModeChanged(AnalyticsTrendMode.expenseOnly),
                ),
                const SizedBox(height: 8),
                AppSecondaryButton(
                  label: l10n.analyticsNetFlow,
                  backgroundColor: trendMode == AnalyticsTrendMode.netFlow
                      ? const Color(0xFFE0F6FF)
                      : Colors.transparent,
                  foregroundColor: AppColors.accentAction,
                  onPressed: () => onTrendModeChanged(AnalyticsTrendMode.netFlow),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: l10n.analyticsExpenseOnly,
                  backgroundColor: trendMode == AnalyticsTrendMode.expenseOnly
                      ? const Color(0xFFE0F6FF)
                      : Colors.transparent,
                  foregroundColor: AppColors.accentAction,
                  onPressed: () => onTrendModeChanged(AnalyticsTrendMode.expenseOnly),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSecondaryButton(
                  label: l10n.analyticsNetFlow,
                  backgroundColor: trendMode == AnalyticsTrendMode.netFlow
                      ? const Color(0xFFE0F6FF)
                      : Colors.transparent,
                  foregroundColor: AppColors.accentAction,
                  onPressed: () => onTrendModeChanged(AnalyticsTrendMode.netFlow),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsFilterBar extends StatelessWidget {
  const _AnalyticsFilterBar({
    required this.filter,
    required this.onOpenFilter,
    required this.onExport,
  });

  final AnalyticsFilter filter;
  final VoidCallback onOpenFilter;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${filter.fromDateLabel} - ${filter.toDateLabel}\n${filter.wallet} • ${filter.category}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppIconButtonCircle(
            icon: Icons.tune_rounded,
            size: 36,
            backgroundColor: AppColors.white,
            iconColor: AppColors.accentAction,
            onPressed: onOpenFilter,
          ),
          const SizedBox(width: 6),
          AppIconButtonCircle(
            icon: Icons.ios_share_rounded,
            size: 36,
            backgroundColor: AppColors.accentAction,
            iconColor: AppColors.white,
            onPressed: onExport,
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.comparison});

  final PeriodComparison comparison;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUp = comparison.deltaPercent >= 0;
    final color = isUp ? const Color(0xFFC10007) : const Color(0xFF008236);
    return SizedBox(
      width: double.infinity,
      child: AppCardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsCompare,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              comparison.mode == AnalyticsCompareMode.monthOverMonth
                  ? l10n.analyticsMonthOverMonth
                  : l10n.analyticsWeekOverWeek,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 4),
            Text(
              '${isUp ? '+' : ''}${comparison.deltaPercent.toStringAsFixed(2)}% ${l10n.analyticsVsPreviousPeriod}',
              style: AppTextStyles.label.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnomalyCard extends StatelessWidget {
  const _AnomalyCard({required this.anomaly});

  final AnomalyInsight anomaly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: AppCardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsAnomalyInsight,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              anomaly.message,
              style: AppTextStyles.body.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAnalyticsView extends StatelessWidget {
  const _EmptyAnalyticsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCardContainer(
      key: const ValueKey('analytics_empty_view'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          AppEmptyAssetPlaceholder(
            label: l10n.analyticsNoDataYet,
            height: 80,
            icon: Icons.data_usage_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.analyticsStartAddingTransactions,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorAnalyticsView extends StatelessWidget {
  const _ErrorAnalyticsView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      key: const ValueKey('analytics_error_view'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFC10007),
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _AnalyticsTopRow extends StatelessWidget {
  const _AnalyticsTopRow({
    required this.name,
    required this.avatarPath,
    required this.onNotificationTap,
  });

  final String name;
  final String avatarPath;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: _avatarImageProvider(avatarPath),
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeGreeting(context),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontSize: 17,
                  height: 22 / 17,
                ),
              ),
              Text(
                name,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.white,
                  fontSize: 30 / 1.36,
                ),
              ),
              StreamBuilder<DateTime>(
                stream: Stream<DateTime>.periodic(
                  const Duration(minutes: 1),
                  (_) => DateTime.now(),
                ),
                initialData: DateTime.now(),
                builder: (context, snapshot) {
                  return Text(
                    formatRealtimeDateLabel(context, snapshot.data),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Row(
          children: [
            AppGlassContainer(
              radius: 15,
              blurSigma: 13.2,
              padding: const EdgeInsets.all(2),
              child: AppIconButtonCircle(
                icon: Icons.notifications_none_rounded,
                size: 30,
                iconColor: AppColors.white,
                backgroundColor: Colors.transparent,
                onPressed: onNotificationTap,
              ),
            ),
            const SizedBox(width: 6),
            const AppGlassContainer(
              radius: 15,
              blurSigma: 13.2,
              padding: EdgeInsets.all(2),
              child: LanguageSwitcherButton(
                iconColor: AppColors.white,
                backgroundColor: Colors.transparent,
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

ImageProvider _avatarImageProvider(String avatarPath) {
  if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
    return NetworkImage(avatarPath);
  }
  return AssetImage(avatarPath);
}
