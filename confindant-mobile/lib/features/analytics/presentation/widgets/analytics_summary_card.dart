import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/app_card_container.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:confindant/features/analytics/presentation/widgets/analytics_formatters.dart';
import 'package:flutter/material.dart';

class AnalyticsSummaryCard extends StatelessWidget {
  const AnalyticsSummaryCard({super.key, required this.summary});

  final AnalyticsSummaryData summary;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: 'Income',
                  value: formatRupiah(summary.totalIncome),
                  valueColor: const Color(0xFF008236),
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _MetricBlock(
                  label: 'Expense',
                  value: formatRupiah(summary.totalExpense),
                  valueColor: const Color(0xFFC10007),
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _MetricBlock(
                  label: 'Saving',
                  value: formatRupiah(summary.netSaving),
                  valueColor: AppColors.blue900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 46,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTextStyles.label.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
