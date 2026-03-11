import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:confindant/core/network/dto_utils.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AnalyticsDataSource {
  Future<AnalyticsLoadedData> fetch(AnalyticsPeriod period);
}

enum AnalyticsSeedMode { normal, empty, error }

class MockAnalyticsDataSource implements AnalyticsDataSource {
  const MockAnalyticsDataSource({this.mode = AnalyticsSeedMode.normal});

  final AnalyticsSeedMode mode;

  @override
  Future<AnalyticsLoadedData> fetch(AnalyticsPeriod period) async {
    if (mode == AnalyticsSeedMode.error) {
      throw StateError('Mock analytics error');
    }

    if (mode == AnalyticsSeedMode.empty) {
      return const AnalyticsLoadedData(
        summary: AnalyticsSummaryData(
          totalIncome: 0,
          totalExpense: 0,
          netSaving: 0,
        ),
        categoryBreakdown: [],
        trendPoints: [],
        budgetProgress: [],
        insightText: '',
      );
    }

    return const AnalyticsLoadedData(
      summary: AnalyticsSummaryData(
        totalIncome: 7600000,
        totalExpense: 5125000,
        netSaving: 2475000,
      ),
      categoryBreakdown: [
        AnalyticsCategorySlice(
          label: 'Food',
          amount: 1780000,
          color: AppColors.blue600,
        ),
      ],
      trendPoints: [AnalyticsTrendPoint(label: 'Mar', amount: 975000)],
      budgetProgress: [
        AnalyticsBudgetItem(category: 'Food', used: 1780000, limit: 2200000),
      ],
      insightText: 'Saving bulan ini naik 18%.',
    );
  }
}

class ApiAnalyticsDataSource implements AnalyticsDataSource {
  const ApiAnalyticsDataSource(this._api);

  final BackendApiService _api;

  @override
  Future<AnalyticsLoadedData> fetch(AnalyticsPeriod period) async {
    final raw = await _api.analytics(
      period: period == AnalyticsPeriod.weekly ? 'weekly' : 'monthly',
    );

    final summary = Map<String, dynamic>.from(
      raw['summary'] as Map? ?? const {},
    );
    final breakdownRaw = (raw['category_breakdown'] as List? ?? const []);
    final trendRaw = (raw['trend_points'] as List? ?? const []);
    final budgetRaw = (raw['budget_progress'] as List? ?? const []);

    return AnalyticsLoadedData(
      summary: AnalyticsSummaryData(
        totalIncome: asDouble(summary['total_income']),
        totalExpense: asDouble(summary['total_expense']),
        netSaving: asDouble(summary['net_saving']),
      ),
      categoryBreakdown: breakdownRaw
          .whereType<Map>()
          .toList()
          .asMap()
          .entries
          .map((entry) {
            final e = Map<String, dynamic>.from(entry.value);
            return AnalyticsCategorySlice(
              label: e['label']?.toString() ?? 'Other',
              amount: asDouble(e['amount']),
              color: _palette(entry.key),
            );
          })
          .toList(),
      trendPoints: trendRaw.whereType<Map>().map((e) {
        final m = Map<String, dynamic>.from(e);
        return AnalyticsTrendPoint(
          label: m['label']?.toString() ?? '-',
          amount: asDouble(m['amount']),
        );
      }).toList(),
      budgetProgress: budgetRaw.whereType<Map>().map((e) {
        final m = Map<String, dynamic>.from(e);
        return AnalyticsBudgetItem(
          category: m['category']?.toString() ?? 'Other',
          used: asDouble(m['used']),
          limit: asDouble(m['limit']),
        );
      }).toList(),
      insightText: raw['insight_text']?.toString() ?? '',
    );
  }

  Color _palette(int i) {
    const colors = [
      AppColors.blue600,
      Color(0xFF00A63E),
      Color(0xFFE7000B),
      Color(0xFF2AA5E6),
      Color(0xFFF59E0B),
    ];
    return colors[i % colors.length];
  }
}

final analyticsDataSourceProvider = Provider<AnalyticsDataSource>((ref) {
  return ApiAnalyticsDataSource(ref.watch(backendApiServiceProvider));
});
