import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/app_api_client.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFinanceApiService extends BackendApiService {
  _FakeFinanceApiService() : super(AppApiClient(baseUrl: 'http://localhost'));

  int createWalletCalls = 0;
  int createBudgetCalls = 0;
  int createTransactionCalls = 0;
  int deleteBudgetCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> wallets() async {
    return [
      {'id': 'w1', 'wallet_name': 'Main Wallet', 'balance': 1000000},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> budgets() async {
    return [
      {
        'id': 'b1',
        'category': 'Food',
        'limit_amount': 500000,
        'period_month': '03-2026',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> dashboard() async {
    return {
      'summary': {'balance': 1000000, 'income': 2000000, 'expense': 1000000},
      'budget_items': [
        {'id': 'b1', 'category': 'Food', 'used': 120000, 'limit': 500000},
      ],
      'recent_transactions': [
        {
          'id': 't1',
          'title': 'Cafe',
          'subtitle': 'Today',
          'amount': 120000,
          'is_expense': true,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> createWallet(Map<String, dynamic> body) async {
    createWalletCalls++;
    return {'id': 'w2', ...body};
  }

  @override
  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> body) async {
    createBudgetCalls++;
    return {'id': 'b2', ...body};
  }

  @override
  Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> body,
  ) async {
    createTransactionCalls++;
    return {'id': 't2', ...body};
  }

  @override
  Future<void> deleteBudget(String id) async {
    deleteBudgetCalls++;
  }
}

void main() {
  test('wallet vm executes wallet/budget/transaction flow', () async {
    final fakeApi = _FakeFinanceApiService();
    final container = ProviderContainer(
      overrides: [backendApiServiceProvider.overrideWithValue(fakeApi)],
    );
    addTearDown(container.dispose);

    final vm = container.read(walletViewModelProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(container.read(walletViewModelProvider).wallets, isNotEmpty);
    expect(container.read(walletViewModelProvider).budgets, isNotEmpty);

    await vm.createWallet(name: 'Savings', balance: 0, color: '#FF0000');
    await vm.createBudget(category: 'Transport', limitAmount: 300000);
    await vm.createTransaction(
      walletId: 'w1',
      type: 'expense',
      category: 'Food',
      totalAmount: 10000,
      merchantName: 'Test',
      notes: 'From test',
    );
    await vm.deleteBudget('b1');

    expect(fakeApi.createWalletCalls, 1);
    expect(fakeApi.createBudgetCalls, 1);
    expect(fakeApi.createTransactionCalls, 1);
    expect(fakeApi.deleteBudgetCalls, 1);
  });
}
