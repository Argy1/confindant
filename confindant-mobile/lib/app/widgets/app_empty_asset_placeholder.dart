import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppEmptyAssetPlaceholder extends StatelessWidget {
  const AppEmptyAssetPlaceholder({
    super.key,
    required this.label,
    this.icon = Icons.image_not_supported_outlined,
    this.height = 120,
  });

  final String label;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.infoStroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accentAction, size: 28),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accentAction,
            ),
          ),
        ],
      ),
    );
  }
}
