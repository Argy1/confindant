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

class BudgetRecommendationItem {
  const BudgetRecommendationItem({
    required this.category,
    required this.currentLimit,
    required this.recommendedLimit,
    required this.used,
    required this.priority,
    required this.reason,
    this.simulationChangePercent,
    this.simulationSavingImpact,
    this.simulationLimit,
  });

  final String category;
  final double currentLimit;
  final double recommendedLimit;
  final double used;
  final String priority;
  final String reason;
  final double? simulationChangePercent;
  final double? simulationSavingImpact;
  final double? simulationLimit;
}

class AnalyticsLoadedData {
  const AnalyticsLoadedData({
    required this.summary,
    required this.categoryBreakdown,
    required this.incomeBreakdown,
    required this.trendPoints,
    required this.incomeTrendPoints,
    required this.netFlowTrend,
    required this.budgetProgress,
    required this.budgetRecommendations,
    required this.comparison,
    required this.anomaly,
    required this.insightText,
  });

  final AnalyticsSummaryData summary;
  final List<AnalyticsCategorySlice> categoryBreakdown;
  final List<AnalyticsCategorySlice> incomeBreakdown;
  final List<AnalyticsTrendPoint> trendPoints;
  final List<AnalyticsTrendPoint> incomeTrendPoints;
  final List<AnalyticsTrendPoint> netFlowTrend;
  final List<AnalyticsBudgetItem> budgetProgress;
  final List<BudgetRecommendationItem> budgetRecommendations;
  final Map<String, dynamic> comparison;
  final Map<String, dynamic> anomaly;
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
