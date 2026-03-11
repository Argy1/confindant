import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/dto_utils.dart';
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
    required this.loading,
  });

  final List<Map<String, dynamic>> wallets;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> budgetItems;
  final List<Map<String, dynamic>> recentTransactions;
  final double income;
  final double expense;
  final double balance;
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
    state = state.copyWith(loading: true);
    try {
      final api = _ref.read(backendApiServiceProvider);
      final wallets = await api.wallets();
      final budgets = await api.budgets();
      final dashboard = await api.dashboard();

      final summary = Map<String, dynamic>.from(
        dashboard['summary'] as Map? ?? const {},
      );
      final budgetItems = (dashboard['budget_items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => _normalizeDto(Map<String, dynamic>.from(e)))
          .toList();
      final recentTransactions =
          (dashboard['recent_transactions'] as List? ?? const [])
              .whereType<Map>()
              .map((e) => _normalizeDto(Map<String, dynamic>.from(e)))
              .toList();

      state = state.copyWith(
        wallets: wallets.map(_normalizeDto).toList(),
        budgets: budgets.map(_normalizeDto).toList(),
        budgetItems: budgetItems,
        recentTransactions: recentTransactions,
        balance: _num(summary['balance']),
        income: _num(summary['income']),
        expense: _num(summary['expense']),
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
    await load();
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
    await load();
  }

  Future<void> deleteWallet(String id) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.deleteWallet(id);
    await load();
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
    await load();
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
    await load();
  }

  Future<void> deleteBudget(String id) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.deleteBudget(id);
    await load();
  }

  Future<void> createTransaction({
    required String walletId,
    required String type,
    required String category,
    required double totalAmount,
    String? merchantName,
    String? notes,
  }) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.createTransaction({
      'wallet_id': walletId,
      'type': type,
      'category': category,
      'total_amount': totalAmount,
      'date': DateTime.now().toIso8601String(),
      'merchant_name': merchantName,
      'notes': notes,
      'is_verified': true,
      'items': [],
    });
    await load();
  }

  Future<void> deleteTransaction(String id) async {
    final api = _ref.read(backendApiServiceProvider);
    await api.deleteTransaction(id);
    await load();
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
}
