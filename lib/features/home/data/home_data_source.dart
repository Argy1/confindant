import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/dto_utils.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:confindant/features/home/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class HomeDataSource {
  Future<HomeDashboardData> fetch();
}

enum HomeSeedMode { normal, empty, error }

class MockHomeDataSource implements HomeDataSource {
  const MockHomeDataSource({this.mode = HomeSeedMode.normal});

  final HomeSeedMode mode;

  @override
  Future<HomeDashboardData> fetch() async {
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
        quickActions: [
          HomeQuickAction(
            type: HomeQuickActionType.scan,
            label: 'Scan',
            icon: Icons.qr_code_scanner_rounded,
          ),
          HomeQuickAction(
            type: HomeQuickActionType.addExpense,
            label: 'Add Expense',
            icon: Icons.remove_circle_outline_rounded,
          ),
          HomeQuickAction(
            type: HomeQuickActionType.addIncome,
            label: 'Add Income',
            icon: Icons.add_circle_outline_rounded,
          ),
          HomeQuickAction(
            type: HomeQuickActionType.addWallet,
            label: 'Add Wallet',
            icon: Icons.account_balance_wallet_outlined,
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
      quickActions: [
        HomeQuickAction(
          type: HomeQuickActionType.scan,
          label: 'Scan',
          icon: Icons.qr_code_scanner_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addExpense,
          label: 'Add Expense',
          icon: Icons.remove_circle_outline_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addIncome,
          label: 'Add Income',
          icon: Icons.add_circle_outline_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addWallet,
          label: 'Add Wallet',
          icon: Icons.account_balance_wallet_outlined,
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
          icon: Icons.local_cafe_outlined,
          iconBackground: Color(0xFFFFF1F2),
        ),
        HomeTransactionItem(
          id: 'mock-income',
          title: 'Salary',
          subtitle: 'Yesterday',
          amount: 5200000,
          isExpense: false,
          icon: Icons.work_outline_rounded,
          iconBackground: Color(0xFFEAFBF1),
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
  Future<HomeDashboardData> fetch() async {
    final data = await _api.dashboard();

    final summary = Map<String, dynamic>.from(
      data['summary'] as Map? ?? const {},
    );
    final budgetItemsRaw = (data['budget_items'] as List? ?? const []);
    final transactionsRaw = (data['recent_transactions'] as List? ?? const []);

    return HomeDashboardData(
      summary: HomeSummaryData(
        balance: _num(summary['balance']),
        income: _num(summary['income']),
        expense: _num(summary['expense']),
        lastUpdatedLabel:
            summary['last_updated_label']?.toString() ?? 'Updated just now',
      ),
      quickActions: const [
        HomeQuickAction(
          type: HomeQuickActionType.scan,
          label: 'Scan',
          icon: Icons.qr_code_scanner_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addExpense,
          label: 'Add Expense',
          icon: Icons.remove_circle_outline_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addIncome,
          label: 'Add Income',
          icon: Icons.add_circle_outline_rounded,
        ),
        HomeQuickAction(
          type: HomeQuickActionType.addWallet,
          label: 'Add Wallet',
          icon: Icons.account_balance_wallet_outlined,
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
      recentTransactions: transactionsRaw.whereType<Map>().map((raw) {
        final item = Map<String, dynamic>.from(raw);
        final isExpense = item['is_expense'] == true;
        return HomeTransactionItem(
          id: normalizeId(item),
          title: item['title']?.toString() ?? 'Transaction',
          subtitle: item['subtitle']?.toString() ?? '',
          amount: asDouble(item['amount']),
          isExpense: isExpense,
          icon: isExpense
              ? Icons.shopping_bag_outlined
              : Icons.account_balance_wallet_outlined,
          iconBackground: isExpense
              ? const Color(0xFFFFF1F2)
              : const Color(0xFFEAFBF1),
        );
      }).toList(),
      insightText: data['insight_text']?.toString() ?? '',
    );
  }

  double _num(dynamic value) {
    return asDouble(value);
  }
}

final homeDataSourceProvider = Provider<HomeDataSource>((ref) {
  return ApiHomeDataSource(ref.watch(backendApiServiceProvider));
});
