import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class PasswordRuleChip extends StatelessWidget {
  const PasswordRuleChip({super.key, required this.label, required this.valid});

  final String label;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final color = valid ? const Color(0xFF008236) : AppColors.textTertiary;
    final bg = valid ? const Color(0xFFEAFBF1) : const Color(0xFFF1F5F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            valid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
