import 'dart:math' as math;

import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/app_card_container.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:flutter/material.dart';

class AnalyticsTrendCard extends StatelessWidget {
  const AnalyticsTrendCard({
    super.key,
    required this.period,
    required this.points,
  });

  final AnalyticsPeriod period;
  final List<AnalyticsTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final title = period == AnalyticsPeriod.weekly
        ? 'Spending Trend (Weekly)'
        : 'Spending Trend (Monthly)';

    return AppCardContainer(
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 130,
            child: CustomPaint(
              size: const Size(double.infinity, 130),
              painter: _BarChartPainter(points: points),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final point in points)
                Expanded(
                  child: Text(
                    point.label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.points});

  final List<AnalyticsTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxValue = points.fold<double>(0, (m, p) => math.max(m, p.amount));
    if (maxValue <= 0) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const horizontalGap = 8.0;
    final barWidth =
        (size.width - ((points.length - 1) * horizontalGap)) / points.length;

    final barPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.blue600, AppColors.blue900],
      ).createShader(Rect.fromLTWH(0, 0, barWidth, size.height));

    for (var i = 0; i < points.length; i++) {
      final value = points[i].amount;
      final normalized = (value / maxValue).clamp(0, 1);
      final barHeight = normalized * (size.height - 4);
      final left = i * (barWidth + horizontalGap);
      final top = size.height - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
