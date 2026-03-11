import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:flutter/material.dart';

class AppIconButtonCircle extends StatelessWidget {
  const AppIconButtonCircle({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 40,
    this.backgroundColor = AppColors.white,
    this.iconColor = AppColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}
