import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/app_card_container.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:confindant/features/analytics/presentation/widgets/analytics_formatters.dart';
import 'package:flutter/material.dart';

class AnalyticsBudgetProgressCard extends StatelessWidget {
  const AnalyticsBudgetProgressCard({super.key, required this.items});

  final List<AnalyticsBudgetItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Progress',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < items.length; i++) ...[
            _BudgetProgressItem(item: items[i]),
            if (i != items.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _BudgetProgressItem extends StatelessWidget {
  const _BudgetProgressItem({required this.item});

  final AnalyticsBudgetItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.progress >= 1
        ? const Color(0xFFC10007)
        : (item.progress >= 0.8 ? const Color(0xFFB26A00) : AppColors.blue600);

    final status = item.progress >= 1
        ? 'Over'
        : (item.progress >= 0.8 ? 'Warning' : 'Safe');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              item.category,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${formatRupiah(item.used)} / ${formatRupiah(item.limit)}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                status,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: item.progress,
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
