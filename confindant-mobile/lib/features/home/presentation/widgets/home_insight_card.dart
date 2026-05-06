import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/app_card_container.dart';
import 'package:flutter/material.dart';

class HomeInsightCard extends StatelessWidget {
  const HomeInsightCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      radius: AppRadius.md,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.accentAction,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
