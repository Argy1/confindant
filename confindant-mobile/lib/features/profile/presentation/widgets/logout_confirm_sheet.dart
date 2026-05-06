import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/app_primary_button.dart';
import 'package:confindant/app/widgets/app_secondary_button.dart';
import 'package:flutter/material.dart';

class LogoutConfirmSheet extends StatelessWidget {
  const LogoutConfirmSheet({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logout',
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Are you sure you want to logout from Confindant?',
              style: AppTextStyles.body.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Cancel',
                    onPressed: onCancel,
                    backgroundColor: const Color(0xFFE5E7EB),
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Logout',
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppColors.white,
                    ),
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
