import 'package:confindant/features/analytics/data/analytics_export_service.dart';
import 'package:confindant/features/analytics/models/advanced_analytics_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final advancedAnalyticsProvider =
    StateNotifierProvider<AdvancedAnalyticsViewModel, AnalyticsFilter>((ref) {
      return AdvancedAnalyticsViewModel();
    });

final exportProvider =
    StateNotifierProvider<ExportViewModel, AsyncValue<ExportResult?>>((ref) {
      return ExportViewModel(ref.watch(analyticsExportServiceProvider));
    });

class AdvancedAnalyticsViewModel extends StateNotifier<AnalyticsFilter> {
  AdvancedAnalyticsViewModel() : super(AnalyticsFilter.initial());

  void updateFilter({
    String? fromDateLabel,
    String? toDateLabel,
    String? wallet,
    String? walletId,
    String? category,
  }) {
    state = state.copyWith(
      fromDateLabel: fromDateLabel,
      toDateLabel: toDateLabel,
      wallet: wallet,
      walletId: walletId,
      category: category,
    );
  }
}

final analyticsExportServiceProvider = Provider<AnalyticsExportService>((ref) {
  return AnalyticsExportService();
});

class ExportViewModel extends StateNotifier<AsyncValue<ExportResult?>> {
  ExportViewModel(this._service) : super(const AsyncValue.data(null));

  final AnalyticsExportService _service;

  Future<void> export(ExportRequest request) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.export(request);
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
