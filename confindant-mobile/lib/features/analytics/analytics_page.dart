import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/analytics/models/advanced_analytics_models.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:confindant/features/analytics/presentation/view_models/advanced_analytics_view_model.dart';
import 'package:confindant/features/analytics/presentation/view_models/analytics_view_model.dart';
import 'package:confindant/features/analytics/presentation/widgets/widgets.dart';
import 'package:confindant/features/goals/presentation/view_models/goals_view_model.dart';
import 'package:confindant/features/home/presentation/widgets/home_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsViewModelProvider);
    final vm = ref.read(analyticsViewModelProvider.notifier);
    final filter = ref.watch(advancedAnalyticsProvider);
    final comparison = ref.watch(periodComparisonProvider);
    final anomaly = ref.watch(anomalyInsightProvider);
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
              _AnalyticsTopRow(onNotificationTap: () {}),
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
                ),
              if (state.uiState == AnalyticsUiState.empty)
                const _EmptyAnalyticsView(),
              if (state.uiState == AnalyticsUiState.error)
                _ErrorAnalyticsView(
                  message:
                      state.errorMessage ?? 'Unable to load analytics data.',
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
  });

  final AnalyticsScreenState state;
  final PeriodComparison comparison;
  final AnomalyInsight anomaly;
  final double goalsSavingImpact;

  @override
  Widget build(BuildContext context) {
    final data = state.data!;
    return Column(
      key: const ValueKey('analytics_loaded_view'),
      children: [
        AnalyticsSummaryCard(summary: data.summary),
        const SizedBox(height: AppSpacing.md),
        AnalyticsDonutBreakdownCard(slices: data.categoryBreakdown),
        const SizedBox(height: AppSpacing.md),
        AnalyticsTrendCard(period: state.period, points: data.trendPoints),
        const SizedBox(height: AppSpacing.md),
        _ComparisonCard(comparison: comparison),
        const SizedBox(height: AppSpacing.md),
        _AnomalyCard(anomaly: anomaly),
        const SizedBox(height: AppSpacing.md),
        AnalyticsBudgetProgressCard(items: data.budgetProgress),
        const SizedBox(height: AppSpacing.md),
        AnalyticsInsightCard(text: data.insightText),
        const SizedBox(height: AppSpacing.md),
        AppCardContainer(
          child: Text(
            'Saving goals impact: ${formatHomeRupiah(goalsSavingImpact)} has been allocated to active goals.',
            style: AppTextStyles.caption.copyWith(fontSize: 13),
          ),
        ),
      ],
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
    final isUp = comparison.deltaPercent >= 0;
    final color = isUp ? const Color(0xFFC10007) : const Color(0xFF008236);
    return SizedBox(
      width: double.infinity,
      child: AppCardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compare',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              comparison.mode == AnalyticsCompareMode.monthOverMonth
                  ? 'Month over Month'
                  : 'Week over Week',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 4),
            Text(
              '${isUp ? '+' : ''}${comparison.deltaPercent.toStringAsFixed(2)}% vs previous period',
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
    return SizedBox(
      width: double.infinity,
      child: AppCardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anomaly Insight',
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
    return AppCardContainer(
      key: const ValueKey('analytics_empty_view'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          const AppEmptyAssetPlaceholder(
            label: 'No analytics data yet',
            height: 80,
            icon: Icons.data_usage_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mulai tambah transaksi agar insight analytics bisa ditampilkan.',
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
  const _AnalyticsTopRow({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage('assets/avatars/analytics_avatar.png'),
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning!',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontSize: 17,
                  height: 22 / 17,
                ),
              ),
              Text(
                'Kennedy',
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.white,
                  fontSize: 30 / 1.36,
                ),
              ),
            ],
          ),
        ),
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
      ],
    );
  }
}
