import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/dto_utils.dart';
import 'package:confindant/features/analytics/presentation/view_models/analytics_view_model.dart';
import 'package:confindant/features/home/presentation/view_models/home_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletScreenState {
  const WalletScreenState({
    required this.wallets,
    required this.budgets,
    required this.budgetItems,
    required this.recentTransactions,
    required this.income,
    required this.expense,
    required this.balance,
    required this.walletStatsById,
    required this.transactionQuery,
    required this.transactionTag,
    required this.loading,
  });

  final List<Map<String, dynamic>> wallets;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> budgetItems;
  final List<Map<String, dynamic>> recentTransactions;
  final double income;
  final double expense;
  final double balance;
  final Map<String, Map<String, double>> walletStatsById;
  final String transactionQuery;
  final String transactionTag;
  final bool loading;

  factory WalletScreenState.initial() {
    return const WalletScreenState(
      wallets: [],
      budgets: [],
      budgetItems: [],
      recentTransactions: [],
      income: 0,
      expense: 0,
      balance: 0,
      walletStatsById: {},
      transactionQuery: '',
      transactionTag: '',
      loading: true,
    );
  }

  WalletScreenState copyWith({
    List<Map<String, dynamic>>? wallets,
    List<Map<String, dynamic>>? budgets,
    List<Map<String, dynamic>>? budgetItems,
    List<Map<String, dynamic>>? recentTransactions,
    double? income,
    double? expense,
    double? balance,
    Map<String, Map<String, double>>? walletStatsById,
    String? transactionQuery,
    String? transactionTag,
    bool? loading,
  }) {
    return WalletScreenState(
      wallets: wallets ?? this.wallets,
      budgets: budgets ?? this.budgets,
      budgetItems: budgetItems ?? this.budgetItems,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      balance: balance ?? this.balance,
      walletStatsById: walletStatsById ?? this.walletStatsById,
      transactionQuery: transactionQuery ?? this.transactionQuery,
      transactionTag: transactionTag ?? this.transactionTag,
      loading: loading ?? this.loading,
    );
  }
}

final walletViewModelProvider =
    StateNotifierProvider<WalletViewModel, WalletScreenState>((ref) {
      return WalletViewModel(ref);
    });

class WalletViewModel extends StateNotifier<WalletScreenState> {
  WalletViewModel(this._ref) : super(WalletScreenState.initial()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    await _loadWithTransactionFilter(
      transactionQuery: state.transactionQuery,
      transactionTag: state.transactionTag,
    );
  }

  Future<void> applyTransactionQuickFilter({
    String? query,
    String? tag,
  }) async {
    await _loadWithTransactionFilter(
      transactionQuery: query ?? state.transactionQuery,
      transactionTag: tag ?? state.transactionTag,
    );
  }

  Future<void> _loadWithTransactionFilter({
    required String transactionQuery,
    required String transactionTag,
  }) async {
    state = state.copyWith(loading: true);
    try {
      final api = _ref.read(backendApiServiceProvider);
      final wallets = await api.wallets();
      final budgets = await api.budgets();
      var dashboard = await api.dashboard();
      final allTransactions = await api.transactions();
      final transactions = await api.pagedTransactions(
        page: 1,
        perPage: 30,
        tag: transactionTag.isEmpty ? null : transactionTag,
        queryText: transactionQuery.isEmpty ? null : transactionQuery,
      );

      final summary = Map<String, dynamic>.from(
        dashboard['summary'] as Map? ?? const {},
      );
      if (_shouldRecalculateWalletBalances(summary)) {
        try {
          await api.recalculateWalletBalances();
          dashboard = await api.dashboard();
        } catch (_) {
          // Keep current state if recalc endpoint unavailable.
        }
      }
      final finalSummary = Map<String, dynamic>.from(
        dashboard['summary'] as Map? ?? const {},
      );
      final budgetItems = (dashboard['budget_items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => _normalizeDto(Map<String, dynamic>.from(e)))
          .toList();
      final recentTransactions = transactions
          .map(_normalizeDto)
          .map(_toWalletTransactionDto)
          .toList();

      state = state.copyWith(
        wallets: _sortWallets(wallets.map(_normalizeDto).toList()),
        budgets: budgets.map(_normalizeDto).toList(),
        budgetItems: budgetItems,
        recentTransactions: recentTransactions,
        walletStatsById: _buildWalletStatsById(
          allTransactions.map(_normalizeDto).toList(),
        ),
        balance: _num(finalSummary['balance']),
        income: _num(finalSummary['income']),
        expense: _num(finalSummary['expense']),
        transactionQuery: transactionQuery,
        transactionTag: transactionTag,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> createWallet({
    required String name,
    required double balance,
    String? color,
  }) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.createWallet({
      'wallet_name': name,
      'balance': balance,
      'wallet_color': color,
    });
    await _reloadAll();
  }

  Future<void> updateWallet({
    required String id,
    required String name,
    required double balance,
    String? color,
  }) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.updateWallet(id, {
      'wallet_name': name,
      'balance': balance,
      'wallet_color': color,
    });
    await _reloadAll();
  }

  Future<void> deleteWallet(String id) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.deleteWallet(id);
    await _reloadAll();
  }

  Future<void> transferBetweenWallets({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? notes,
    DateTime? date,
  }) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.transferWalletBalance(
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      notes: notes,
      date: date,
    );
    await _reloadAll();
  }

  Future<void> createBudget({
    required String category,
    required double limitAmount,
    String periodMonth = '03-2026',
  }) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.createBudget({
      'category': category,
      'limit_amount': limitAmount,
      'period_month': periodMonth,
      'alert_threshold': 80,
    });
    await _reloadAll();
  }

  Future<void> updateBudget({
    required String id,
    required String category,
    required double limitAmount,
    String periodMonth = '03-2026',
  }) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.updateBudget(id, {
      'category': category,
      'limit_amount': limitAmount,
      'period_month': periodMonth,
      'alert_threshold': 80,
    });
    await _reloadAll();
  }

  Future<void> deleteBudget(String id) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.deleteBudget(id);
    await _reloadAll();
  }

  Future<Map<String, dynamic>> createTransaction({
    required String walletId,
    required String type,
    required String category,
    required double totalAmount,
    String? source,
    DateTime? date,
    bool isVerified = true,
    String? merchantName,
    String? notes,
    List<String>? tags,
  }) async {
    final api = _ref.read(backendApiServiceProvider);
    final created = await api.createTransaction({
      'wallet_id': walletId,
      'type': type,
      'category': category,
      'total_amount': totalAmount,
      'source': source,
      'date': (date ?? DateTime.now()).toIso8601String(),
      'merchant_name': merchantName,
      'notes': notes,
      'tags': tags ?? const <String>[],
      'is_verified': isVerified,
      'items': [],
    });
    await _reloadAll();
    return created;
  }

  Future<Map<String, dynamic>> updateTransaction({
    required String id,
    required String walletId,
    required String type,
    required String category,
    required double totalAmount,
    String? source,
    DateTime? date,
    bool isVerified = true,
    String? merchantName,
    String? notes,
    List<String>? tags,
  }) async {
    final api = _ref.read(backendApiServiceProvider);
    final updated = await api.updateTransaction(id, {
      'wallet_id': walletId,
      'type': type,
      'category': category,
      'total_amount': totalAmount,
      'source': source,
      'date': (date ?? DateTime.now()).toIso8601String(),
      'merchant_name': merchantName,
      'notes': notes,
      'tags': tags ?? const <String>[],
      'is_verified': isVerified,
      'items': [],
    });
    await _reloadAll();
    return updated;
  }

  Future<void> deleteTransaction(String id) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.deleteTransaction(id);
    await _reloadAll();
  }

  double _num(dynamic value) {
    return asDouble(value);
  }

  Map<String, dynamic> _normalizeDto(Map<String, dynamic> dto) {
    final normalized = Map<String, dynamic>.from(dto);
    final id = normalizeId(normalized);
    if (id.isNotEmpty) {
      normalized['id'] = id;
    }
    return normalized;
  }

  List<Map<String, dynamic>> _sortWallets(List<Map<String, dynamic>> wallets) {
    final sorted = [...wallets];
    sorted.sort((a, b) {
      final aCreated = DateTime.tryParse(a['created_at']?.toString() ?? '');
      final bCreated = DateTime.tryParse(b['created_at']?.toString() ?? '');
      if (aCreated != null && bCreated != null) {
        return aCreated.compareTo(bCreated);
      }
      if (aCreated != null) return -1;
      if (bCreated != null) return 1;
      return 0;
    });
    return sorted;
  }

  Future<void> _reloadAll() async {
    await _loadWithTransactionFilter(
      transactionQuery: state.transactionQuery,
      transactionTag: state.transactionTag,
    );
    await _ref.read(homeViewModelProvider.notifier).load();
    _ref.read(analyticsViewModelProvider.notifier).retry();
  }

  Map<String, dynamic> _toWalletTransactionDto(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? 'expense';
    final merchant = item['merchant_name']?.toString().trim() ?? '';
    final source = item['source']?.toString().trim() ?? '';
    final category = item['category']?.toString().trim() ?? '';
    final title = merchant.isNotEmpty
        ? merchant
        : (type == 'income' ? (source.isNotEmpty ? source : 'Income') : (category.isNotEmpty ? category : 'Expense'));

    return {
      ...item,
      'title' : title,
      'amount': _num(item['total_amount']),
      'is_expense': type == 'expense',
      'tags': (item['tags'] as List? ?? const []).map((e) => e.toString()).toList(),
      'ai_suggested': item['ai_suggested'] == true,
      'ai_provider': item['ai_provider']?.toString(),
    };
  }

  Map<String, Map<String, double>> _buildWalletStatsById(
    List<Map<String, dynamic>> transactions,
  ) {
    final stats = <String, Map<String, double>>{};
    for (final tx in transactions) {
      final walletId = tx['wallet_id']?.toString() ?? '';
      if (walletId.isEmpty) continue;
      final type = tx['type']?.toString() ?? 'expense';
      final amount = _num(tx['total_amount']);
      final entry = stats.putIfAbsent(
        walletId,
        () => <String, double>{'income': 0, 'expense': 0},
      );
      if (type == 'income') {
        entry['income'] = (entry['income'] ?? 0) + amount;
      } else {
        entry['expense'] = (entry['expense'] ?? 0) + amount;
      }
    }
    return stats;
  }

  bool _shouldRecalculateWalletBalances(Map<String, dynamic> summary) {
    final balance = _num(summary['balance']);
    final income = _num(summary['income']);
    final expense = _num(summary['expense']);
    final net = income - expense;
    final delta = (balance - net).abs();
    return income > 0 && delta > 10000;
  }
}
