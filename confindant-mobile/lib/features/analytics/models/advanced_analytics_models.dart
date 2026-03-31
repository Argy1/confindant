enum AnalyticsCompareMode { weekOverWeek, monthOverMonth }

class AnalyticsFilter {
  const AnalyticsFilter({
    required this.fromDateLabel,
    required this.toDateLabel,
    required this.wallet,
    required this.category,
  });

  final String fromDateLabel;
  final String toDateLabel;
  final String wallet;
  final String category;

  factory AnalyticsFilter.initial() {
    return const AnalyticsFilter(
      fromDateLabel: '2026-03-01',
      toDateLabel: '2026-03-31',
      wallet: 'All Wallets',
      category: 'All Categories',
    );
  }

  AnalyticsFilter copyWith({
    String? fromDateLabel,
    String? toDateLabel,
    String? wallet,
    String? category,
  }) {
    return AnalyticsFilter(
      fromDateLabel: fromDateLabel ?? this.fromDateLabel,
      toDateLabel: toDateLabel ?? this.toDateLabel,
      wallet: wallet ?? this.wallet,
      category: category ?? this.category,
    );
  }
}

class PeriodComparison {
  const PeriodComparison({
    required this.mode,
    required this.currentValue,
    required this.previousValue,
    required this.deltaPercent,
  });

  final AnalyticsCompareMode mode;
  final double currentValue;
  final double previousValue;
  final double deltaPercent;
}

class AnomalyInsight {
  const AnomalyInsight({
    required this.category,
    required this.spikePercent,
    required this.message,
  });

  final String category;
  final double spikePercent;
  final String message;
}

enum ExportFormat { csv, pdf }

class ExportRequest {
  const ExportRequest({required this.format, required this.filter});

  final ExportFormat format;
  final AnalyticsFilter filter;
}

class ExportResult {
  const ExportResult({
    required this.fileName,
    required this.success,
    required this.message,
  });

  final String fileName;
  final bool success;
  final String message;
}
