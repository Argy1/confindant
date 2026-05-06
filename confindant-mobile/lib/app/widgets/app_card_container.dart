import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_shadows.dart';
import 'package:flutter/material.dart';

class AppCardContainer extends StatelessWidget {
  const AppCardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = AppRadius.md,
    this.useElevatedShadow = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double radius;
  final bool useElevatedShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: useElevatedShadow
            ? AppShadows.elevatedCard
            : AppShadows.card,
      ),
      child: child,
    );
  }
}
