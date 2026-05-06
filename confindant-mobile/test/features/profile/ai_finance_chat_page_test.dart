import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/app_api_client.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:confindant/features/profile/ai_finance_chat_page.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBackendApiService extends BackendApiService {
  _FakeBackendApiService() : super(AppApiClient(baseUrl: 'http://localhost'));

  int aiFinanceQueryCalls = 0;
  String? lastQuery;
  int historyCalls = 0;
  int clearHistoryCalls = 0;

  @override
  Future<Map<String, dynamic>> aiFinanceQuery({
    required String query,
    String locale = 'id',
  }) async {
    aiFinanceQueryCalls++;
    lastQuery = query;
    return {
      'query': query,
      'answer': 'Pengeluaran terbesar bulan ini ada di kategori Food.',
      'insight': 'Food naik 18% dibanding bulan lalu.',
      'suggested_actions': [
        'Batasi makan di luar maksimal 3x per minggu.',
        'Aktifkan budget alert kategori Food.',
      ],
      'provider': 'fallback',
      'fallback': true,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> aiFinanceQueryHistory({int limit = 20}) async {
    historyCalls++;
    return [
      {
        'id': 'h1',
        'query': 'Riwayat lama',
        'answer': 'Jawaban riwayat',
        'insight': 'Insight riwayat',
        'suggested_actions': ['Aksi 1'],
      },
    ];
  }

  @override
  Future<void> clearAiFinanceQueryHistory() async {
    clearHistoryCalls++;
  }
}

void main() {
  testWidgets('ai finance chat quick ask sends query and renders response', (tester) async {
    final fakeApi = _FakeBackendApiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendApiServiceProvider.overrideWithValue(fakeApi),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AiFinanceChatPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chat Keuangan AI'), findsOneWidget);
    final quickAskFinder = find.text('Bulan ini paling boros di mana?');
    await tester.ensureVisible(quickAskFinder);
    await tester.tap(quickAskFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(fakeApi.aiFinanceQueryCalls, 1);
    expect(fakeApi.lastQuery, 'Bulan ini paling boros di mana?');
    expect(fakeApi.historyCalls, 1);
    expect(find.textContaining('kategori Food'), findsOneWidget);

    final clearFinder = find.text('Hapus Riwayat');
    await tester.ensureVisible(clearFinder);
    await tester.tap(clearFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(fakeApi.clearHistoryCalls, 1);
  });
}
