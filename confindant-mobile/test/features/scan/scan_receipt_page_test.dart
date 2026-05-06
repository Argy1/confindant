import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/app_api_client.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:confindant/features/scan/scan_receipt_page.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeBackendApiService extends BackendApiService {
  _FakeBackendApiService({
    this.ocrStatus = 'success',
    this.ocrErrorCode,
  }) : super(AppApiClient(baseUrl: 'http://localhost'));

  int uploadCalls = 0;
  String? lastFilePath;
  int ocrSubmitCalls = 0;
  int ocrCommitCalls = 0;
  int ocrFeedbackCalls = 0;
  int createTransactionCalls = 0;
  final String ocrStatus;
  final String? ocrErrorCode;

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

  @override
  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> body) async {
    createTransactionCalls++;
    return {
      'id': 'trx-manual',
      ...body,
    };
  }

  @override
  Future<Map<String, dynamic>> submitScanOcr({required String filePath}) async {
    ocrSubmitCalls++;
    return {
      'id': 'ocr1',
      'status': ocrStatus,
      'confidence': 0.8,
      'error_code': ocrErrorCode,
      'receipt_image_url': '/receipts/x.jpg',
      'extracted': {
        'merchant_name': 'Store Name',
        'type': 'expense',
        'category': 'Shopping',
        'total_amount': 55000,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getScanOcr(String jobId) async {
    return {
      'id': jobId,
      'status': ocrStatus,
      'confidence': 0.8,
      'error_code': ocrErrorCode,
      'error_message': ocrStatus == 'failed' ? 'provider fail' : null,
      'receipt_image_url': '/receipts/x.jpg',
      'extracted': {
        'merchant_name': 'Store Name',
        'type': 'expense',
        'category': 'Shopping',
        'total_amount': 55000,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> commitScanOcr(
    String jobId,
    Map<String, dynamic> body,
  ) async {
    ocrCommitCalls++;
    return {
      'id': 'trx-ocr',
      ...body,
      'ocr_status': 'success',
    };
  }

  @override
  Future<Map<String, dynamic>> submitScanOcrFeedback(
    String jobId,
    Map<String, dynamic> body,
  ) async {
    ocrFeedbackCalls++;
    return {
      'id': 'feedback1',
      'ocr_job_id': jobId,
      ...body,
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
      walletStatsById: {},
      transactionQuery: '',
      transactionTag: '',
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
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();
    final saveFinder = find.text('Save');
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(fakeApi.ocrSubmitCalls, 1);
    expect(fakeApi.ocrCommitCalls, 1);
    expect(fakeApi.ocrFeedbackCalls, 1);
    expect(fakeApi.createTransactionCalls, 0);
  });

  testWidgets('manual mode saves via create transaction without ocr/upload', (
    tester,
  ) async {
    final fakeApi = _FakeBackendApiService();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: ScanReceiptPage(),
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
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Manual Entry'), findsOneWidget);

    final amountField = find.widgetWithText(TextField, 'Total Amount');
    await tester.enterText(amountField, '250000');

    final saveFinder = find.text('Save');
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(fakeApi.createTransactionCalls, 1);
    expect(fakeApi.ocrSubmitCalls, 0);
    expect(fakeApi.ocrCommitCalls, 0);
    expect(fakeApi.uploadCalls, 0);
  });

  testWidgets('failed OCR shows continue manual CTA and still allows save', (
    tester,
  ) async {
    final fakeApi = _FakeBackendApiService(
      ocrStatus: 'failed',
      ocrErrorCode: 'quota_exhausted',
    );
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
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Continue Manually'), findsOneWidget);

    final amountField = find.widgetWithText(TextField, 'Total Amount');
    await tester.enterText(amountField, '100000');

    final saveFinder = find.text('Save');
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(fakeApi.ocrSubmitCalls, 1);
    expect(fakeApi.ocrCommitCalls, 0);
    expect(fakeApi.uploadCalls, 1);
    expect(fakeApi.ocrFeedbackCalls, 1);

    final retryFinder = find.text('Retry OCR');
    await tester.ensureVisible(retryFinder);
    await tester.tap(retryFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(fakeApi.ocrSubmitCalls, 2);
  });
}
