import 'package:flutter/material.dart';

enum HomeUiState { loaded, empty, error }

enum HomeQuickActionType { scan, addExpense, addIncome, addWallet, voiceInput }

class HomeSummaryData {
  const HomeSummaryData({
    required this.balance,
    required this.income,
    required this.expense,
    required this.lastUpdatedLabel,
  });

  final double balance;
  final double income;
  final double expense;
  final String lastUpdatedLabel;
}

class HomeCashflowForecast {
  const HomeCashflowForecast({
    required this.horizonDays,
    required this.predictedBalance,
    required this.predictedNet,
    required this.willGoNegative,
    required this.negativeOnDate,
    required this.daysToNegative,
    required this.confidence,
    required this.provider,
  });

  final int horizonDays;
  final double predictedBalance;
  final double predictedNet;
  final bool willGoNegative;
  final String? negativeOnDate;
  final int? daysToNegative;
  final double confidence;
  final String provider;
}

class HomeQuickAction {
  const HomeQuickAction({
    required this.type,
    required this.label,
    required this.icon,
  });

  final HomeQuickActionType type;
  final String label;
  final IconData icon;
}

class HomeBudgetItem {
  const HomeBudgetItem({
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

class HomeTransactionItem {
  const HomeTransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
    required this.type,
    required this.icon,
    required this.iconBackground,
    this.category,
    this.source,
    this.notes,
    this.tags = const [],
    this.aiSuggested = false,
    this.aiProvider,
  });

  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isExpense;
  final String type;
  final IconData icon;
  final Color iconBackground;
  final String? category;
  final String? source;
  final String? notes;
  final List<String> tags;
  final bool aiSuggested;
  final String? aiProvider;
}

class HomeDashboardData {
  const HomeDashboardData({
    required this.summary,
    required this.cashflowForecast,
    required this.quickActions,
    required this.budgetItems,
    required this.recentTransactions,
    required this.insightText,
  });

  final HomeSummaryData summary;
  final HomeCashflowForecast? cashflowForecast;
  final List<HomeQuickAction> quickActions;
  final List<HomeBudgetItem> budgetItems;
  final List<HomeTransactionItem> recentTransactions;
  final String insightText;
}

class HomeScreenState {
  const HomeScreenState({
    required this.uiState,
    this.data,
    this.errorMessage,
    this.transactionQuery = '',
    this.transactionTag = '',
  });

  final HomeUiState uiState;
  final HomeDashboardData? data;
  final String? errorMessage;
  final String transactionQuery;
  final String transactionTag;

  factory HomeScreenState.initial() {
    return const HomeScreenState(uiState: HomeUiState.loaded);
  }

  HomeScreenState copyWith({
    HomeUiState? uiState,
    HomeDashboardData? data,
    String? errorMessage,
    String? transactionQuery,
    String? transactionTag,
    bool clearError = false,
  }) {
    return HomeScreenState(
      uiState: uiState ?? this.uiState,
      data: data ?? this.data,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      transactionQuery: transactionQuery ?? this.transactionQuery,
      transactionTag: transactionTag ?? this.transactionTag,
    );
  }
}
