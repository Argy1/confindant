import 'dart:math' as math;

import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/app_card_container.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:confindant/features/analytics/presentation/widgets/analytics_formatters.dart';
import 'package:flutter/material.dart';

class AnalyticsDonutBreakdownCard extends StatelessWidget {
  const AnalyticsDonutBreakdownCard({super.key, required this.slices});

  final List<AnalyticsCategorySlice> slices;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.amount);
    return AppCardContainer(
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 330;
              if (compact) {
                return Column(
                  children: [
                    _DonutCanvas(slices: slices, total: total),
                    const SizedBox(height: 14),
                    ...slices.map((s) => _LegendItem(slice: s, total: total)),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DonutCanvas(slices: slices, total: total),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        for (final slice in slices)
                          _LegendItem(slice: slice, total: total),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DonutCanvas extends StatelessWidget {
  const _DonutCanvas({required this.slices, required this.total});

  final List<AnalyticsCategorySlice> slices;
  final double total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: CustomPaint(
        painter: _DonutPainter(slices: slices),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total', style: AppTextStyles.caption),
              Text(
                formatRupiah(total),
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.slice, required this.total});

  final AnalyticsCategorySlice slice;
  final double total;

  @override
  Widget build(BuildContext context) {
    final percentage = total <= 0 ? 0 : (slice.amount / total * 100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: slice.color,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(slice.label, style: AppTextStyles.label)),
          const SizedBox(width: 8),
          Text(
            formatRupiah(slice.amount),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices});

  final List<AnalyticsCategorySlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..color = AppColors.divider;

    canvas.drawCircle(center, radius - 9, trackPaint);

    final total = slices.fold<double>(0, (sum, item) => sum + item.amount);
    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweep = (slice.amount / total) * (math.pi * 2);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..color = slice.color;

      final safeSweep = math.max(0.0, sweep - 0.05).toDouble();
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 9),
        startAngle,
        safeSweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}
