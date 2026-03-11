import 'package:flutter/material.dart';

enum AnalyticsPeriod { weekly, monthly }

enum AnalyticsUiState { loaded, empty, error }

class AnalyticsSummaryData {
  const AnalyticsSummaryData({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSaving,
  });

  final double totalIncome;
  final double totalExpense;
  final double netSaving;
}

class AnalyticsCategorySlice {
  const AnalyticsCategorySlice({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;
}

class AnalyticsTrendPoint {
  const AnalyticsTrendPoint({required this.label, required this.amount});

  final String label;
  final double amount;
}

class AnalyticsBudgetItem {
  const AnalyticsBudgetItem({
    required this.category,
    required this.used,
    required this.limit,
  });

  final String category;
  final double used;
  final double limit;

  double get progress {
    if (limit <= 0) return 0;
    return (used / limit).clamp(0, 1);
  }
}

class AnalyticsLoadedData {
  const AnalyticsLoadedData({
    required this.summary,
    required this.categoryBreakdown,
    required this.trendPoints,
    required this.budgetProgress,
    required this.insightText,
  });

  final AnalyticsSummaryData summary;
  final List<AnalyticsCategorySlice> categoryBreakdown;
  final List<AnalyticsTrendPoint> trendPoints;
  final List<AnalyticsBudgetItem> budgetProgress;
  final String insightText;
}

class AnalyticsScreenState {
  const AnalyticsScreenState({
    required this.period,
    required this.uiState,
    this.data,
    this.errorMessage,
  });

  final AnalyticsPeriod period;
  final AnalyticsUiState uiState;
  final AnalyticsLoadedData? data;
  final String? errorMessage;

  factory AnalyticsScreenState.initial() {
    return const AnalyticsScreenState(
      period: AnalyticsPeriod.monthly,
      uiState: AnalyticsUiState.loaded,
    );
  }

  AnalyticsScreenState copyWith({
    AnalyticsPeriod? period,
    AnalyticsUiState? uiState,
    AnalyticsLoadedData? data,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnalyticsScreenState(
      period: period ?? this.period,
      uiState: uiState ?? this.uiState,
      data: data ?? this.data,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
