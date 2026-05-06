import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/ai/ai_settings_controller.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/utils/time_greeting.dart';
import 'package:confindant/features/analytics/presentation/view_models/analytics_view_model.dart';
import 'package:confindant/features/goals/models/goals_models.dart';
import 'package:confindant/features/goals/presentation/view_models/goals_view_model.dart';
import 'package:confindant/features/home/models/home_models.dart';
import 'package:confindant/features/home/presentation/view_models/home_view_model.dart';
import 'package:confindant/features/home/presentation/widgets/widgets.dart';
import 'package:confindant/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:confindant/features/transactions/transaction_form_dialog.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _balanceVisible = true;
  final SpeechToText _speechToText = SpeechToText();
  bool _isVoiceQuickActionListening = false;

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);
    final goals = ref.watch(goalsViewModelProvider);
    final profile = ref.watch(profileSettingsProvider).userData;
    final summary =
        state.data?.summary ??
        const HomeSummaryData(
          balance: 0,
          income: 0,
          expense: 0,
          lastUpdatedLabel: '',
        );

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.appBackground),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(31, 62, 31, 140),
          child: Column(
            children: [
              _TopGreetingRow(
                name: profile.fullName.isEmpty ? 'User' : profile.fullName,
                avatarPath: profile.avatarPath,
                onNotificationTap: () => context.push(RoutePaths.profileNotifications),
              ),
              const SizedBox(height: AppSpacing.xl),
              _BalanceHeroCard(
                summary: summary,
                balanceVisible: _balanceVisible,
                onToggleVisibility: () {
                  setState(() => _balanceVisible = !_balanceVisible);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.uiState == HomeUiState.loaded && state.data != null)
                _LoadedSections(
                  data: state.data!,
                  onQuickActionTap: (type) => _onQuickActionTap(type),
                  isVoiceQuickActionListening: _isVoiceQuickActionListening,
                  onDeleteTransaction: (id) => _deleteTransaction(id),
                  onEditTransaction: (item) => _editTransaction(item),
                  goals: goals,
                  onSeeAllTransactions: () => context.push(RoutePaths.wallet),
                  activeTag: state.transactionTag,
                  activeQuery: state.transactionQuery,
                  onTagFilterSelected: (tag) {
                    ref
                        .read(homeViewModelProvider.notifier)
                        .applyTransactionQuickFilter(tag: tag);
                  },
                  onSearchTap: () => _showHomeTransactionSearchDialog(state.transactionQuery),
                ),
              if (state.uiState == HomeUiState.empty) const _EmptySections(),
              if (state.uiState == HomeUiState.error)
                _ErrorSections(
                  message: state.errorMessage ?? l10n.homeUnableLoadDashboard,
                  onRetry: () => vm.load(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onQuickActionTap(HomeQuickActionType type) async {
    switch (type) {
      case HomeQuickActionType.scan:
        context.push(RoutePaths.scan);
        return;
      case HomeQuickActionType.addWallet:
        context.push(RoutePaths.addWallet);
        return;
      case HomeQuickActionType.addExpense:
        await _createQuickTransaction(isExpense: true);
        return;
      case HomeQuickActionType.addIncome:
        await _createQuickTransaction(isExpense: false);
        return;
      case HomeQuickActionType.voiceInput:
        await _createTransactionFromVoiceQuickAction();
        return;
    }
  }

  Future<void> _createTransactionFromVoiceQuickAction() async {
    final l10n = AppLocalizations.of(context)!;
    final walletState = ref.read(walletViewModelProvider);
    if (walletState.wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homePleaseCreateWalletFirst)),
      );
      return;
    }

    if (_isVoiceQuickActionListening) {
      await _speechToText.stop();
      await HapticFeedback.selectionClick();
      return;
    }

    final micGranted = await _ensureMicrophonePermission(l10n);
    if (!micGranted || !mounted) return;

    String transcript = '';
    final initialized = await _speechToText.initialize(
      onError: (SpeechRecognitionError error) {
        if (!mounted) return;
        setState(() => _isVoiceQuickActionListening = false);
        final message = error.permanent
            ? l10n.transactionFormVoicePermissionDenied
            : l10n.transactionFormVoiceUnavailable;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
      onStatus: (status) async {
        if (!mounted) return;
        if (status == 'notListening' && _isVoiceQuickActionListening) {
          await HapticFeedback.selectionClick();
          setState(() => _isVoiceQuickActionListening = false);
          await _openPrefilledFormFromTranscript(transcript, walletState.wallets);
        }
      },
    );

    if (!mounted) return;
    if (!initialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transactionFormVoiceUnavailable)),
      );
      return;
    }

    final localeId = Localizations.localeOf(context).languageCode == 'en' ? 'en_US' : 'id_ID';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.homeVoiceQuickActionListening)),
    );

    await _speechToText.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (result) {
        transcript = result.recognizedWords.trim();
      },
    );

    if (!mounted) return;
    setState(() => _isVoiceQuickActionListening = true);
    await HapticFeedback.lightImpact();
  }

  Future<bool> _ensureMicrophonePermission(AppLocalizations l10n) async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;

    status = await Permission.microphone.request();
    if (status.isGranted) return true;

    final message = status.isPermanentlyDenied
        ? l10n.transactionFormVoicePermissionDenied
        : l10n.transactionFormVoiceUnavailable;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  Future<void> _openPrefilledFormFromTranscript(
    String transcript,
    List<Map<String, dynamic>> wallets,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final text = transcript.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transactionFormVoiceNoSpeech)),
      );
      return;
    }

    try {
      final locale = Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'id';
      final parsed = await ref.read(backendApiServiceProvider).aiParseTransactionInput(
            transcript: text,
            locale: locale,
          );
      if (!mounted) return;

      final walletId = wallets.first['id']?.toString() ??
          wallets.first['_id']?.toString() ??
          '';
      final parsedType = parsed['type']?.toString() == 'income' ? 'income' : 'expense';
      final parsedAmount = double.tryParse(parsed['amount']?.toString() ?? '') ?? 0;
      final parsedCategory = (parsed['category']?.toString().trim() ?? '').isEmpty
          ? (parsedType == 'income' ? 'Other Income' : 'Other Expense')
          : parsed['category'].toString().trim();
      final parsedSource = parsed['source']?.toString().trim() ?? '';
      final parsedMerchant = parsed['merchant_name']?.toString().trim() ?? '';
      final parsedNotes = parsed['notes']?.toString().trim() ?? text;
      final parsedDate = DateTime.tryParse(parsed['date']?.toString() ?? '') ?? DateTime.now();

      final initial = TransactionFormResult(
        walletId: walletId,
        type: parsedType,
        amount: parsedAmount,
        category: parsedCategory,
        source: parsedSource,
        merchantName: parsedMerchant,
        notes: parsedNotes,
        tags: const [],
        date: parsedDate,
        isVerified: true,
        aiSuggestedCategory: parsedCategory,
        aiConfidence: double.tryParse(parsed['confidence']?.toString() ?? ''),
        aiProvider: parsed['provider']?.toString(),
        aiInputContext: {
          'transcript': text,
          'mode': 'voice_quick_action',
        },
      );

      final form = await showTransactionFormDialog(
        context,
        wallets: wallets,
        defaultIncome: parsedType == 'income',
        initial: initial,
        aiCategorizationEnabled: ref.read(aiSettingsProvider).autoCategorizationEnabled,
        onAiSuggestCategory: (payload) => ref
            .read(backendApiServiceProvider)
            .aiSuggestTransactionCategory(payload),
        onAiParseVoiceTransaction: (voiceTranscript, locale) => ref
            .read(backendApiServiceProvider)
            .aiParseTransactionInput(transcript: voiceTranscript, locale: locale),
      );
      if (form == null) return;

      final created = await ref.read(backendApiServiceProvider).createTransaction({
        'wallet_id': form.walletId,
        'type': form.type,
        'category': form.category,
        'total_amount': form.amount,
        'source': form.source,
        'date': form.date.toIso8601String(),
        'merchant_name': form.merchantName,
        'notes': form.notes,
        'tags': form.tags,
        'is_verified': form.isVerified,
        'items': [],
      });
      await _submitAiCategoryFeedback(form, transactionId: created['id']?.toString());

      await ref.read(homeViewModelProvider.notifier).load();
      await ref.read(walletViewModelProvider.notifier).load();
      ref.read(analyticsViewModelProvider.notifier).retry();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeVoiceQuickActionSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transactionFormVoiceParseFailed)),
      );
    }
  }

  Future<void> _createQuickTransaction({required bool isExpense}) async {
    final l10n = AppLocalizations.of(context)!;
    final walletState = ref.read(walletViewModelProvider);
    if (walletState.wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homePleaseCreateWalletFirst)),
      );
      return;
    }
    final form = await showTransactionFormDialog(
      context,
      wallets: walletState.wallets,
      defaultIncome: !isExpense,
      lockedType: isExpense ? 'expense' : 'income',
      aiCategorizationEnabled: ref
          .read(aiSettingsProvider)
          .autoCategorizationEnabled,
      onAiSuggestCategory: (payload) => ref
          .read(backendApiServiceProvider)
          .aiSuggestTransactionCategory(payload),
      onAiParseVoiceTransaction: (transcript, locale) => ref
          .read(backendApiServiceProvider)
          .aiParseTransactionInput(transcript: transcript, locale: locale),
    );
    if (form == null) return;

    final created = await ref.read(backendApiServiceProvider).createTransaction({
      'wallet_id': form.walletId,
      'type': form.type,
      'category': form.category,
      'total_amount': form.amount,
      'source': form.source,
      'date': form.date.toIso8601String(),
      'merchant_name': form.merchantName,
      'notes': form.notes,
      'tags': form.tags,
      'is_verified': form.isVerified,
      'items': [],
    });
    await _submitAiCategoryFeedback(form, transactionId: created['id']?.toString());

    await ref.read(homeViewModelProvider.notifier).load();
    await ref.read(walletViewModelProvider.notifier).load();
    ref.read(analyticsViewModelProvider.notifier).retry();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isExpense ? l10n.homeExpenseAdded : l10n.homeIncomeAdded),
      ),
    );
  }

  Future<void> _deleteTransaction(String id) async {
    final l10n = AppLocalizations.of(context)!;
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transactionFormInvalidInput)),
      );
      return;
    }

    await ref.read(backendApiServiceProvider).deleteTransaction(id);
    await ref.read(homeViewModelProvider.notifier).load();
    await ref.read(walletViewModelProvider.notifier).load();
    ref.read(analyticsViewModelProvider.notifier).retry();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.homeTransactionDeleted)));
  }

  Future<void> _editTransaction(HomeTransactionItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final walletState = ref.read(walletViewModelProvider);
    if (walletState.wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homePleaseCreateWalletFirst)),
      );
      return;
    }

    final initial = TransactionFormResult(
      walletId: walletState.wallets.first['id']?.toString() ??
          walletState.wallets.first['_id']?.toString() ??
          '',
      type: item.type,
      amount: item.amount,
      category: item.category ?? (item.isExpense ? 'General Expense' : 'Salary'),
      source: item.source ?? (item.isExpense ? '' : 'Other'),
      merchantName: item.title,
      notes: item.notes ?? '',
      tags: item.tags,
      date: DateTime.now(),
      isVerified: true,
    );

    final form = await showTransactionFormDialog(
      context,
      wallets: walletState.wallets,
      defaultIncome: item.type == 'income',
      initial: initial,
      aiCategorizationEnabled: ref
          .read(aiSettingsProvider)
          .autoCategorizationEnabled,
      onAiSuggestCategory: (payload) => ref
          .read(backendApiServiceProvider)
          .aiSuggestTransactionCategory(payload),
      onAiParseVoiceTransaction: (transcript, locale) => ref
          .read(backendApiServiceProvider)
          .aiParseTransactionInput(transcript: transcript, locale: locale),
    );
    if (form == null) return;

    await ref.read(backendApiServiceProvider).updateTransaction(item.id, {
      'wallet_id': form.walletId,
      'type': form.type,
      'total_amount': form.amount,
      'category': form.category,
      'source': form.source,
      'merchant_name': form.merchantName,
      'notes': form.notes,
      'tags': form.tags,
      'date': form.date.toIso8601String(),
      'is_verified': form.isVerified,
    });
    await _submitAiCategoryFeedback(form, transactionId: item.id);
    await ref.read(homeViewModelProvider.notifier).load();
    await ref.read(walletViewModelProvider.notifier).load();
    ref.read(analyticsViewModelProvider.notifier).retry();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.homeTransactionUpdated)),
    );
  }

  Future<void> _showHomeTransactionSearchDialog(String initialQuery) async {
    final controller = TextEditingController(text: initialQuery);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Search Transactions'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Search by merchant, category, source, notes, or tags',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(homeViewModelProvider.notifier)
                    .applyTransactionQuickFilter(query: '');
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(homeViewModelProvider.notifier)
                    .applyTransactionQuickFilter(query: controller.text.trim());
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _submitAiCategoryFeedback(
    TransactionFormResult form, {
    required String? transactionId,
  }) async {
    final suggested = form.aiSuggestedCategory?.trim();
    if (suggested == null || suggested.isEmpty) {
      return;
    }

    await ref.read(backendApiServiceProvider).aiSubmitTransactionCategoryFeedback({
      'transaction_id': transactionId,
      'suggested_category': suggested,
      'final_category': form.category,
      'accepted': suggested.toLowerCase() == form.category.toLowerCase(),
      'confidence': form.aiConfidence,
      'provider': form.aiProvider,
      'input_context': form.aiInputContext,
    });
  }
}

class _LoadedSections extends StatelessWidget {
  const _LoadedSections({
    required this.data,
    required this.onQuickActionTap,
    required this.isVoiceQuickActionListening,
    required this.onDeleteTransaction,
    required this.onEditTransaction,
    required this.goals,
    required this.onSeeAllTransactions,
    required this.activeTag,
    required this.activeQuery,
    required this.onTagFilterSelected,
    required this.onSearchTap,
  });

  final HomeDashboardData data;
  final ValueChanged<HomeQuickActionType> onQuickActionTap;
  final bool isVoiceQuickActionListening;
  final ValueChanged<String> onDeleteTransaction;
  final ValueChanged<HomeTransactionItem> onEditTransaction;
  final List<GoalData> goals;
  final VoidCallback onSeeAllTransactions;
  final String activeTag;
  final String activeQuery;
  final ValueChanged<String> onTagFilterSelected;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('home_loaded_view'),
      children: [
        HomeQuickActionsCard(
          actions: data.quickActions,
          onActionTap: onQuickActionTap,
          isVoiceListening: isVoiceQuickActionListening,
        ),
        if (data.cashflowForecast != null) ...[
          const SizedBox(height: AppSpacing.md),
          _CashflowForecastCard(forecast: data.cashflowForecast!),
        ],
        const SizedBox(height: AppSpacing.md),
        _GoalsSummaryCard(goalCount: goals.length),
        const SizedBox(height: AppSpacing.md),
        HomeBudgetSnapshotCard(items: data.budgetItems),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChipItem(
              label: 'All',
              selected: activeTag.isEmpty,
              onTap: () => onTagFilterSelected(''),
            ),
            _FilterChipItem(
              label: 'kerja',
              selected: activeTag == 'kerja',
              onTap: () => onTagFilterSelected('kerja'),
            ),
            _FilterChipItem(
              label: 'urgent',
              selected: activeTag == 'urgent',
              onTap: () => onTagFilterSelected('urgent'),
            ),
            _FilterChipItem(
              label: 'keluarga',
              selected: activeTag == 'keluarga',
              onTap: () => onTagFilterSelected('keluarga'),
            ),
            OutlinedButton.icon(
              onPressed: onSearchTap,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(activeQuery.isEmpty ? 'Search' : 'Search: $activeQuery'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        HomeRecentTransactionsCard(
          items: data.recentTransactions,
          onSeeAllTap: onSeeAllTransactions,
          onDeleteTap: (item) => onDeleteTransaction(item.id),
          onEditTap: onEditTransaction,
        ),
        const SizedBox(height: AppSpacing.md),
        HomeInsightCard(text: data.insightText),
      ],
    );
  }
}

class _CashflowForecastCard extends StatelessWidget {
  const _CashflowForecastCard({required this.forecast});

  final HomeCashflowForecast forecast;

  @override
  Widget build(BuildContext context) {
    final isPositive = forecast.predictedNet >= 0;
    final netLabel = '${isPositive ? '+' : ''}${formatHomeRupiah(forecast.predictedNet)}';
    return AppCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'AI Cashflow Forecast (${forecast.horizonDays}d)',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              const Spacer(),
              Text(
                '${(forecast.confidence * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Predicted balance: ${formatHomeRupiah(forecast.predictedBalance)}',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Net movement: $netLabel',
            style: AppTextStyles.caption.copyWith(
              color: isPositive ? const Color(0xFF0A7A34) : const Color(0xFFC10007),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (forecast.willGoNegative && forecast.negativeOnDate != null) ...[
            const SizedBox(height: 6),
            Text(
              'Warning: balance may go below Rp 0 on ${forecast.negativeOnDate}.',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFC10007),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalsSummaryCard extends StatelessWidget {
  const _GoalsSummaryCard({required this.goalCount});

  final int goalCount;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Savings Goals',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(RoutePaths.goals),
                child: Text(
                  'Open',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accentAction,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$goalCount active goal(s) • track your progress and top-up routinely.',
            style: AppTextStyles.caption.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EmptySections extends StatelessWidget {
  const _EmptySections();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCardContainer(
      key: const ValueKey('home_empty_view'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          AppEmptyAssetPlaceholder(
            label: l10n.homeNoTransactionsYet,
            icon: Icons.receipt_long_rounded,
            height: 80,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.homeStartAddingTransactions,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorSections extends StatelessWidget {
  const _ErrorSections({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      key: const ValueKey('home_error_view'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFC10007),
            size: 34,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _BalanceHeroCard extends StatelessWidget {
  const _BalanceHeroCard({
    required this.summary,
    required this.balanceVisible,
    required this.onToggleVisibility,
  });

  final HomeSummaryData summary;
  final bool balanceVisible;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Your Balance',
                style: AppTextStyles.body.copyWith(
                  color: Colors.black.withValues(alpha: 0.7),
                  fontSize: 17,
                  height: 22 / 17,
                ),
              ),
              const SizedBox(width: 12),
              AppIconButtonCircle(
                icon: balanceVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 30,
                backgroundColor: Colors.transparent,
                iconColor: AppColors.textSecondary,
                onPressed: onToggleVisibility,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              balanceVisible
                  ? formatHomeRupiah(summary.balance)
                  : 'Rp. **********',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle.copyWith(
                fontSize: 32,
                height: 1.05,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.lastUpdatedLabel,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _IncomeExpenseCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Income',
                  value: formatHomeRupiah(summary.income),
                  gradient: const [Color(0xFF005B22), Color(0xFF0A2472)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _IncomeExpenseCard(
                  icon: Icons.trending_down_rounded,
                  label: 'Expense',
                  value: formatHomeRupiah(summary.expense),
                  gradient: const [Color(0xFFA20003), Color(0xFF0A2472)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopGreetingRow extends StatelessWidget {
  const _TopGreetingRow({
    required this.name,
    required this.avatarPath,
    required this.onNotificationTap,
  });

  final String name;
  final String avatarPath;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: _avatarImageProvider(avatarPath),
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeGreeting(context),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                  fontSize: 17,
                ),
              ),
              Text(
                name,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.white,
                  fontSize: 32 / 1.46,
                ),
              ),
              StreamBuilder<DateTime>(
                stream: Stream<DateTime>.periodic(
                  const Duration(minutes: 1),
                  (_) => DateTime.now(),
                ),
                initialData: DateTime.now(),
                builder: (context, snapshot) {
                  return Text(
                    formatRealtimeDateLabel(context, snapshot.data),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Row(
          children: [
            AppGlassContainer(
              radius: 15,
              blurSigma: 13.2,
              padding: const EdgeInsets.all(2),
              child: AppIconButtonCircle(
                icon: Icons.notifications_none_rounded,
                size: 30,
                backgroundColor: Colors.transparent,
                iconColor: AppColors.white,
                onPressed: onNotificationTap,
              ),
            ),
            const SizedBox(width: 6),
            const AppGlassContainer(
              radius: 15,
              blurSigma: 13.2,
              padding: EdgeInsets.all(2),
              child: LanguageSwitcherButton(
                iconColor: AppColors.white,
                backgroundColor: Colors.transparent,
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

ImageProvider _avatarImageProvider(String avatarPath) {
  if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
    return NetworkImage(avatarPath);
  }
  return AssetImage(avatarPath);
}

class _IncomeExpenseCard extends StatelessWidget {
  const _IncomeExpenseCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.white,
                    fontSize: 18,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
