import 'package:confindant/features/analytics/models/advanced_analytics_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final advancedAnalyticsProvider =
    StateNotifierProvider<AdvancedAnalyticsViewModel, AnalyticsFilter>((ref) {
      return AdvancedAnalyticsViewModel();
    });

final periodComparisonProvider = Provider<PeriodComparison>((ref) {
  final filter = ref.watch(advancedAnalyticsProvider);
  final mode = filter.toDateLabel.contains('-03-')
      ? AnalyticsCompareMode.monthOverMonth
      : AnalyticsCompareMode.weekOverWeek;
  return PeriodComparison(
    mode: mode,
    currentValue: 5125000,
    previousValue: 4730000,
    deltaPercent: 8.35,
  );
});

final anomalyInsightProvider = Provider<AnomalyInsight>((ref) {
  final filter = ref.watch(advancedAnalyticsProvider);
  final category = filter.category == 'All Categories'
      ? 'Shopping'
      : filter.category;
  return AnomalyInsight(
    category: category,
    spikePercent: 18.2,
    message:
        '$category spending spiked 18.2% versus previous period. Consider setting tighter limits.',
  );
});

final exportProvider =
    StateNotifierProvider<ExportViewModel, AsyncValue<ExportResult?>>((ref) {
      return ExportViewModel();
    });

class AdvancedAnalyticsViewModel extends StateNotifier<AnalyticsFilter> {
  AdvancedAnalyticsViewModel() : super(AnalyticsFilter.initial());

  void updateFilter({
    String? fromDateLabel,
    String? toDateLabel,
    String? wallet,
    String? category,
  }) {
    state = state.copyWith(
      fromDateLabel: fromDateLabel,
      toDateLabel: toDateLabel,
      wallet: wallet,
      category: category,
    );
  }
}

class ExportViewModel extends StateNotifier<AsyncValue<ExportResult?>> {
  ExportViewModel() : super(const AsyncValue.data(null));

  Future<void> export(ExportRequest request) async {
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final ext = request.format == ExportFormat.csv ? 'csv' : 'pdf';
    final fileName = 'analytics_${DateTime.now().millisecondsSinceEpoch}.$ext';
    state = AsyncValue.data(
      ExportResult(
        fileName: fileName,
        success: true,
        message: 'Mock export generated. Ready to share.',
      ),
    );
  }
}
