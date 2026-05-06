import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/dto_utils.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:confindant/features/home/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class HomeDataSource {
  Future<HomeDashboardData> fetch({
    String transactionTag = '',
    String transactionQuery = '',
  });
}

enum HomeSeedMode { normal, empty, error }

class MockHomeDataSource implements HomeDataSource {
  const MockHomeDataSource({this.mode = HomeSeedMode.normal});

  final HomeSeedMode mode;

  @override
  Future<HomeDashboardData> fetch({
    String transactionTag = '',
    String transactionQuery = '',
  }) async {
    if (mode == HomeSeedMode.error) {
      throw StateError('Mock home error');
    }

    if (mode == HomeSeedMode.empty) {
      return const HomeDashboardData(
        summary: HomeSummaryData(
          balance: 0,
          income: 0,
          expense: 0,
          lastUpdatedLabel: 'Updated just now',
        ),
        cashflowForecast: null,
        quickActions: [
          HomeQuickAction(
            type: HomeQuickActionType.scan,
            label: 'Scan',
            icon: Icons.qr_code_scanner_rounded,
          ),
          HomeQuickAction(
            type: HomeQuickActionType.addExpense,
            label: 'Tambah Pengeluaran',
            icon: Icons.remove_circle_outline_rounded,
          ),
          HomeQuickAction(
            type: HomeQuickActionType.addIncome,
            label: 'Tambah Pemasukan',
            icon: Icons.add_circle_outline_rounded,
          ),
          HomeQuickAction(
            type: HomeQuickActionType.addWallet,
            label: 'Add Wallet',
            icon: Icons.account_balance_wallet_outlined,
          ),
          HomeQuickAction(
            type: HomeQuickActionType.voiceInput,
            label: 'Input Suara',
            icon: Icons.mic_none_rounded,
          ),
        ],
        budgetItems: [],
        recentTransactions: [],
        insightText: 'Belum ada data transaksi untuk ditampilkan.',
      );
    }

    return const HomeDashboardData(
      summary: HomeSummaryData(
        balance: 123456789,
        income: 7600000,
        expense: 5125000,
        lastUpdatedLabel: 'Updated 5 minutes ago',
      ),
      cashflowForecast: HomeCashflowForecast(
        horizonDays: 30,
        predictedBalance: 125900000,
        predictedNet: 2440000,
        willGoNegative: false,
        negativeOnDate: null,
        daysToNegative: null,
        confidence: 0.71,
        provider: 'heuristic',
      ),
      quickActions: [
        HomeQuickAction(
          type: HomeQuickActionType.scan,
          label: 'Scan',
          icon: Icons.qr_code_scanner_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addExpense,
          label: 'Tambah Pengeluaran',
          icon: Icons.remove_circle_outline_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addIncome,
          label: 'Tambah Pemasukan',
          icon: Icons.add_circle_outline_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addWallet,
          label: 'Add Wallet',
          icon: Icons.account_balance_wallet_outlined,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.voiceInput,
          label: 'Input Suara',
          icon: Icons.mic_none_rounded,
        ),
      ],
      budgetItems: [
        HomeBudgetItem(category: 'Food', used: 1780000, limit: 2200000),
      ],
      recentTransactions: [
        HomeTransactionItem(
          id: 'mock-expense',
          title: 'Coffee Shop',
          subtitle: 'Today',
          amount: 48000,
          isExpense: true,
          type: 'expense',
          icon: Icons.local_cafe_outlined,
          iconBackground: Color(0xFFFFF1F2),
          category: 'Food',
          source: null,
          notes: 'Mock expense',
          tags: ['keluarga'],
          aiSuggested: false,
          aiProvider: null,
        ),
        HomeTransactionItem(
          id: 'mock-income',
          title: 'Salary',
          subtitle: 'Yesterday',
          amount: 5200000,
          isExpense: false,
          type: 'income',
          icon: Icons.work_outline_rounded,
          iconBackground: Color(0xFFEAFBF1),
          category: 'Salary',
          source: 'Salary',
          notes: 'Mock income',
          tags: ['kerja'],
          aiSuggested: false,
          aiProvider: null,
        ),
      ],
      insightText: 'Spending minggu ini naik 8%.',
    );
  }
}

class ApiHomeDataSource implements HomeDataSource {
  const ApiHomeDataSource(this._api);

  final BackendApiService _api;

  @override
  Future<HomeDashboardData> fetch({
    String transactionTag = '',
    String transactionQuery = '',
  }) async {
    var data = await _api.dashboard();
    final initialSummary = Map<String, dynamic>.from(
      data['summary'] as Map? ?? const {},
    );
    if (_shouldRecalculateWalletBalances(initialSummary)) {
      try {
        await _api.recalculateWalletBalances();
        data = await _api.dashboard();
      } catch (_) {
        // Keep best-effort dashboard response when recalc endpoint is unavailable.
      }
    }
    final transactions = await _api.pagedTransactions(
      page: 1,
      perPage: 8,
      tag: transactionTag.isEmpty ? null : transactionTag,
      queryText: transactionQuery.isEmpty ? null : transactionQuery,
    );

    final summary = Map<String, dynamic>.from(
      data['summary'] as Map? ?? const {},
    );
    final budgetItemsRaw = (data['budget_items'] as List? ?? const []);
    final forecastRaw = Map<String, dynamic>.from(
      ((data['cashflow_forecast'] as Map?)?['next_30_days'] as Map?) ?? const {},
    );

    final incomeValue = _num(summary['income']);
    final expenseValue = _num(summary['expense']);
    final rawBalance = _num(summary['balance']);
    final effectiveBalance = rawBalance == 0 && (incomeValue != 0 || expenseValue != 0)
        ? incomeValue - expenseValue
        : rawBalance;

    return HomeDashboardData(
      summary: HomeSummaryData(
        balance: effectiveBalance,
        income: incomeValue,
        expense: expenseValue,
        lastUpdatedLabel:
            summary['last_updated_label']?.toString() ?? 'Updated just now',
      ),
      cashflowForecast: forecastRaw.isEmpty
          ? null
          : HomeCashflowForecast(
              horizonDays: asInt(forecastRaw['horizon_days']),
              predictedBalance: asDouble(forecastRaw['predicted_balance']),
              predictedNet: asDouble(forecastRaw['predicted_net']),
              willGoNegative: forecastRaw['will_go_negative'] == true,
              negativeOnDate: forecastRaw['negative_on_date']?.toString(),
              daysToNegative: forecastRaw['days_to_negative'] is num
                  ? (forecastRaw['days_to_negative'] as num).toInt()
                  : int.tryParse('${forecastRaw['days_to_negative'] ?? ''}'),
              confidence: asDouble(forecastRaw['confidence']),
              provider: forecastRaw['provider']?.toString() ?? 'unknown',
            ),
      quickActions: const [
        HomeQuickAction(
          type: HomeQuickActionType.scan,
          label: 'Scan',
          icon: Icons.qr_code_scanner_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addExpense,
          label: 'Tambah Pengeluaran',
          icon: Icons.remove_circle_outline_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addIncome,
          label: 'Tambah Pemasukan',
          icon: Icons.add_circle_outline_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addWallet,
          label: 'Add Wallet',
          icon: Icons.account_balance_wallet_outlined,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.voiceInput,
          label: 'Input Suara',
          icon: Icons.mic_none_rounded,
        ),
      ],
      budgetItems: budgetItemsRaw.whereType<Map>().map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return HomeBudgetItem(
          category: item['category']?.toString() ?? 'Other',
          used: _num(item['used']),
          limit: _num(item['limit']),
        );
      }).toList(),
      recentTransactions: transactions.map((item) {
        final type = item['type']?.toString() ?? 'expense';
        final isExpense = type == 'expense';
        final merchant = item['merchant_name']?.toString().trim() ?? '';
        final source = item['source']?.toString().trim() ?? '';
        final category = item['category']?.toString().trim() ?? '';
        final title = merchant.isNotEmpty
            ? merchant
            : (isExpense ? (category.isNotEmpty ? category : 'Expense') : (source.isNotEmpty ? source : 'Income'));
        final dateValue = item['date']?.toString() ?? '';
        return HomeTransactionItem(
          id: normalizeId(item),
          title: title,
          subtitle: _formatDateLabel(dateValue),
          amount: asDouble(item['total_amount']),
          isExpense: isExpense,
          type: type,
          icon: isExpense
              ? Icons.shopping_bag_outlined
              : Icons.account_balance_wallet_outlined,
          iconBackground: isExpense
              ? const Color(0xFFFFF1F2)
              : const Color(0xFFEAFBF1),
          category: item['category']?.toString(),
          source: item['source']?.toString(),
          notes: item['notes']?.toString(),
          tags: (item['tags'] as List? ?? const []).map((e) => e.toString()).toList(),
          aiSuggested: item['ai_suggested'] == true,
          aiProvider: item['ai_provider']?.toString(),
        );
      }).toList(),
      insightText: data['insight_text']?.toString() ?? '',
    );
  }

  double _num(dynamic value) {
    return asDouble(value);
  }

  String _formatDateLabel(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

final homeDataSourceProvider = Provider<HomeDataSource>((ref) {
  return ApiHomeDataSource(ref.watch(backendApiServiceProvider));
});
