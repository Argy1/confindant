import 'package:confindant/features/analytics/data/analytics_data_source.dart';
import 'package:confindant/features/analytics/models/analytics_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsViewModelProvider =
    StateNotifierProvider<AnalyticsViewModel, AnalyticsScreenState>((ref) {
      return AnalyticsViewModel(ref.watch(analyticsDataSourceProvider));
    });

class AnalyticsViewModel extends StateNotifier<AnalyticsScreenState> {
  AnalyticsViewModel(this._dataSource) : super(AnalyticsScreenState.initial()) {
    _load();
  }

  final AnalyticsDataSource _dataSource;

  void setPeriod(AnalyticsPeriod period) {
    if (state.period == period) return;
    state = state.copyWith(period: period);
    _load();
  }

  void retry() => _load();

  Future<void> _load() async {
    try {
      final data = await _dataSource.fetch(state.period);
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
