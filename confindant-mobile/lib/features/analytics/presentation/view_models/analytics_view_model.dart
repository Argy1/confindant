import 'package:confindant/features/analytics/data/analytics_data_source.dart';
import 'package:confindant/features/analytics/models/advanced_analytics_models.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:confindant/features/analytics/presentation/view_models/advanced_analytics_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsViewModelProvider =
    StateNotifierProvider<AnalyticsViewModel, AnalyticsScreenState>((ref) {
      return AnalyticsViewModel(ref, ref.watch(analyticsDataSourceProvider));
    });

class AnalyticsViewModel extends StateNotifier<AnalyticsScreenState> {
  AnalyticsViewModel(this._ref, this._dataSource)
    : super(AnalyticsScreenState.initial()) {
    _load();
  }

  final Ref _ref;
  final AnalyticsDataSource _dataSource;

  void setPeriod(AnalyticsPeriod period) {
    if (state.period == period) return;
    state = state.copyWith(period: period);
    _load();
  }

  void retry() => _load();

  Future<void> _load() async {
    try {
      final filter = _ref.read(advancedAnalyticsProvider);
      final data = await _dataSource.fetch(state.period, filter);
      state = state.copyWith(
        data: data,
        uiState: _isEmptyData(data)
            ? AnalyticsUiState.empty
            : AnalyticsUiState.loaded,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        uiState: AnalyticsUiState.error,
        errorMessage: 'Unable to load analytics data right now.',
      );
    }
  }

  bool _isEmptyData(AnalyticsLoadedData data) {
    final isSummaryZero =
        data.summary.totalIncome == 0 &&
        data.summary.totalExpense == 0 &&
        data.summary.netSaving == 0;

    return isSummaryZero &&
        data.categoryBreakdown.isEmpty &&
        data.trendPoints.isEmpty &&
        data.budgetProgress.isEmpty;
  }
}

final periodComparisonProvider = Provider<PeriodComparison>((ref) {
  final data = ref.watch(analyticsViewModelProvider).data;
  final map = Map<String, dynamic>.from(
    data?.comparison ??
        const {
          'mode': 'monthOverMonth',
          'current_value': 0,
          'previous_value': 0,
          'delta_percent': 0,
        },
  );
  final mode = map['mode']?.toString() == 'weekOverWeek'
      ? AnalyticsCompareMode.weekOverWeek
      : AnalyticsCompareMode.monthOverMonth;
  return PeriodComparison(
    mode: mode,
    currentValue: _num(map['current_value']),
    previousValue: _num(map['previous_value']),
    deltaPercent: _num(map['delta_percent']),
  );
});

final anomalyInsightProvider = Provider<AnomalyInsight>((ref) {
  final data = ref.watch(analyticsViewModelProvider).data;
  final map = Map<String, dynamic>.from(
    data?.anomaly ?? const {'category': 'None', 'spike_percent': 0, 'message': ''},
  );
  final category = map['category']?.toString() ?? 'None';
  return AnomalyInsight(
    category: category,
    spikePercent: _num(map['spike_percent']),
    message: map['message']?.toString() ?? 'No anomaly insight available yet.',
  );
});

double _num(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
