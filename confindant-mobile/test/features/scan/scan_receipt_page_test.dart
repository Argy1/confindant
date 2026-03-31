import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/app_api_client.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:confindant/features/scan/scan_receipt_page.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeBackendApiService extends BackendApiService {
  _FakeBackendApiService() : super(AppApiClient(baseUrl: 'http://localhost'));

  int uploadCalls = 0;
  String? lastFilePath;

  @override
  Future<List<Map<String, dynamic>>> wallets() async {
    return [
      {'id': 'w1', 'wallet_name': 'Main Wallet', 'balance': 1000},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> budgets() async => const [];

  @override
  Future<Map<String, dynamic>> dashboard() async {
    return {
      'summary': {'balance': 1000, 'income': 0, 'expense': 0},
      'budget_items': const [],
      'recent_transactions': const [],
      'insight_text': '',
    };
  }

  @override
  Future<Map<String, dynamic>> uploadReceipt({
    required Map<String, dynamic> fields,
    String? filePath,
  }) async {
    uploadCalls++;
    lastFilePath = filePath;
    return {
      'id': 'trx-scan',
      ...fields,
      'receipt_image_url': '/receipts/x.jpg',
    };
  }
}

class _FakeWalletViewModel extends WalletViewModel {
  _FakeWalletViewModel(super.ref) {
    state = const WalletScreenState(
      wallets: [
        {'id': 'w1', 'wallet_name': 'Main', 'balance': 1000},
      ],
      budgets: [],
      budgetItems: [],
      recentTransactions: [],
      income: 0,
      expense: 0,
      balance: 1000,
      loading: false,
    );
  }

  @override
  Future<void> load() async {}
}

void main() {
  testWidgets('scan receipt save submits upload payload', (tester) async {
    final fakeApi = _FakeBackendApiService();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: ScanReceiptPage(initialImagePath: '/tmp/receipt.jpg'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendApiServiceProvider.overrideWithValue(fakeApi),
          walletViewModelProvider.overrideWith(
            (ref) => _FakeWalletViewModel(ref),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    final saveFinder = find.text('Save');
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(fakeApi.uploadCalls, 1);
    expect(fakeApi.lastFilePath, '/tmp/receipt.jpg');
  });
}
