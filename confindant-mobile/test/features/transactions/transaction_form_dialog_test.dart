import 'package:confindant/features/transactions/transaction_form_dialog.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ai suggestion is shown and metadata returned on submit', (
    tester,
  ) async {
    late BuildContext hostContext;
    final suggestionCalls = <Map<String, dynamic>>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    final dialogFuture = showTransactionFormDialog(
      hostContext,
      wallets: const [
        {'id': 'w1', 'wallet_name': 'Main Wallet'},
      ],
      defaultIncome: false,
      aiCategorizationEnabled: true,
      onAiSuggestCategory: (payload) async {
        suggestionCalls.add(payload);
        return {
          'category': 'Food',
          'confidence': 0.82,
          'provider': 'gemini',
        };
      },
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(3), 'Coffee Shop');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.textContaining('AI suggestion: Food'), findsOneWidget);
    expect(suggestionCalls, isNotEmpty);

    await tester.enterText(find.byType(TextField).at(1), 'Dining');
    await tester.enterText(find.byType(TextField).at(0), '50000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final result = await dialogFuture;
    expect(result, isNotNull);
    expect(result!.category, 'Dining');
    expect(result.aiSuggestedCategory, 'Food');
    expect(result.aiProvider, 'gemini');
    expect(result.aiConfidence, 0.82);
    expect(result.aiInputContext?['merchant_name'], 'Coffee Shop');
  });
}
