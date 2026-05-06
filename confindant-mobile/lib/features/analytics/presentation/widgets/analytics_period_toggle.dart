import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/app_glass_container.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:flutter/material.dart';

class AnalyticsPeriodToggle extends StatelessWidget {
  const AnalyticsPeriodToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      radius: AppRadius.lg,
      blurSigma: 12,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _PeriodChip(
              key: const ValueKey('analytics_period_weekly'),
              label: 'Weekly',
              active: selected == AnalyticsPeriod.weekly,
              onTap: () => onChanged(AnalyticsPeriod.weekly),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PeriodChip(
              key: const ValueKey('analytics_period_monthly'),
              label: 'Monthly',
              active: selected == AnalyticsPeriod.monthly,
              onTap: () => onChanged(AnalyticsPeriod.monthly),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: active ? AppColors.blue900 : AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
