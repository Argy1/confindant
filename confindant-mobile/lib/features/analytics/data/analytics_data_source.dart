import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:confindant/core/network/dto_utils.dart';
import 'package:confindant/features/analytics/models/advanced_analytics_models.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AnalyticsDataSource {
  Future<AnalyticsLoadedData> fetch(AnalyticsPeriod period, AnalyticsFilter filter);
}

enum AnalyticsSeedMode { normal, empty, error }

class MockAnalyticsDataSource implements AnalyticsDataSource {
  const MockAnalyticsDataSource({this.mode = AnalyticsSeedMode.normal});

  final AnalyticsSeedMode mode;

  @override
  Future<AnalyticsLoadedData> fetch(AnalyticsPeriod period, AnalyticsFilter filter) async {
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
        incomeBreakdown: [],
        trendPoints: [],
        incomeTrendPoints: [],
        netFlowTrend: [],
        budgetProgress: [],
        budgetRecommendations: [],
        comparison: {
          'mode': 'monthOverMonth',
          'current_value': 0,
          'previous_value': 0,
          'delta_percent': 0,
        },
        anomaly: {'category': 'None', 'spike_percent': 0, 'message': ''},
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
      incomeBreakdown: [
        AnalyticsCategorySlice(
          label: 'Salary',
          amount: 7600000,
          color: Color(0xFF00A63E),
        ),
      ],
      trendPoints: [AnalyticsTrendPoint(label: 'Mar', amount: 975000)],
      incomeTrendPoints: [AnalyticsTrendPoint(label: 'Mar', amount: 7600000)],
      netFlowTrend: [AnalyticsTrendPoint(label: 'Mar', amount: 2475000)],
      budgetProgress: [
        AnalyticsBudgetItem(category: 'Food', used: 1780000, limit: 2200000),
      ],
      budgetRecommendations: [
        BudgetRecommendationItem(
          category: 'Food',
          currentLimit: 2200000,
          recommendedLimit: 2500000,
          used: 1780000,
          priority: 'medium',
          reason: 'Penggunaan kategori cukup tinggi.',
          simulationChangePercent: -10,
          simulationSavingImpact: 220000,
          simulationLimit: 1980000,
        ),
      ],
      comparison: {
        'mode': 'monthOverMonth',
        'current_value': 5125000,
        'previous_value': 4730000,
        'delta_percent': 8.35,
      },
      anomaly: {
        'category': 'Food',
        'spike_percent': 18.2,
        'message': 'Food spending spiked 18.2% versus previous period.',
      },
      insightText: 'Saving bulan ini naik 18%.',
    );
  }
}

class ApiAnalyticsDataSource implements AnalyticsDataSource {
  const ApiAnalyticsDataSource(this._api);

  final BackendApiService _api;

  @override
  Future<AnalyticsLoadedData> fetch(AnalyticsPeriod period, AnalyticsFilter filter) async {
    final raw = await _api.analytics(
      period: period == AnalyticsPeriod.weekly ? 'weekly' : 'monthly',
      fromDate: filter.fromDateLabel,
      toDate: filter.toDateLabel,
      walletId: filter.walletId.isEmpty ? null : filter.walletId,
      category: filter.category == 'All Categories' ? null : filter.category,
    );

    final summary = Map<String, dynamic>.from(
      raw['summary'] as Map? ?? const {},
    );
    final breakdownRaw = (raw['category_breakdown'] as List? ?? const []);
    final incomeBreakdownRaw = (raw['income_breakdown'] as List? ?? const []);
    final trendRaw = (raw['trend_points'] as List? ?? const []);
    final incomeTrendRaw = (raw['income_trend_points'] as List? ?? const []);
    final netFlowRaw = (raw['net_flow_trend'] as List? ?? const []);
    final budgetRaw = (raw['budget_progress'] as List? ?? const []);
    final recommendationRaw = (raw['budget_recommendations'] as List? ?? const []);

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
      incomeBreakdown: incomeBreakdownRaw
          .whereType<Map>()
          .toList()
          .asMap()
          .entries
          .map((entry) {
            final e = Map<String, dynamic>.from(entry.value);
            return AnalyticsCategorySlice(
              label: e['label']?.toString() ?? 'Other',
              amount: asDouble(e['amount']),
              color: _palette(entry.key + 1),
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
      incomeTrendPoints: incomeTrendRaw.whereType<Map>().map((e) {
        final m = Map<String, dynamic>.from(e);
        return AnalyticsTrendPoint(
          label: m['label']?.toString() ?? '-',
          amount: asDouble(m['amount']),
        );
      }).toList(),
      netFlowTrend: netFlowRaw.whereType<Map>().map((e) {
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
      budgetRecommendations: recommendationRaw.whereType<Map>().map((e) {
        final m = Map<String, dynamic>.from(e);
        final simulation = Map<String, dynamic>.from(
          m['simulation_if_reduce_10_percent'] as Map? ?? const {},
        );
        return BudgetRecommendationItem(
          category: m['category']?.toString() ?? 'Other',
          currentLimit: asDouble(m['current_limit']),
          recommendedLimit: asDouble(m['recommended_limit']),
          used: asDouble(m['used']),
          priority: m['priority']?.toString() ?? 'low',
          reason: m['reason']?.toString() ?? '',
          simulationChangePercent: simulation.isEmpty
              ? null
              : asDouble(simulation['change_percent']),
          simulationSavingImpact: simulation.isEmpty
              ? null
              : asDouble(simulation['estimated_saving_impact']),
          simulationLimit: simulation.isEmpty
              ? null
              : asDouble(simulation['simulated_limit']),
        );
      }).toList(),
      comparison: Map<String, dynamic>.from(
        raw['comparison'] as Map? ??
            const {
              'mode': 'monthOverMonth',
              'current_value': 0,
              'previous_value': 0,
              'delta_percent': 0,
            },
      ),
      anomaly: Map<String, dynamic>.from(
        raw['anomaly'] as Map? ??
            const {'category': 'None', 'spike_percent': 0, 'message': ''},
      ),
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
