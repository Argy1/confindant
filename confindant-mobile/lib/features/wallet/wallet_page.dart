import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/ai/ai_settings_controller.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:confindant/core/utils/time_greeting.dart';
import 'package:confindant/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:confindant/features/transactions/transaction_form_dialog.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(walletViewModelProvider);
    final profile = ref.watch(profileSettingsProvider).userData;
    final firstWallet = state.wallets.isNotEmpty ? state.wallets.first : null;
    final firstWalletId = firstWallet?['id']?.toString() ??
        firstWallet?['_id']?.toString() ??
        '';
    final walletName = firstWallet?['wallet_name']?.toString() ?? 'Main Wallet';
    final mainWalletBalance = _num(firstWallet?['balance']);
    final activeWalletStats = state.walletStatsById[firstWalletId] ?? const {'income': 0.0, 'expense': 0.0};
    final extraWallets = state.wallets.length > 1
        ? state.wallets.skip(1).toList()
        : const <Map<String, dynamic>>[];

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.appBackground),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(31, 62, 31, 140),
          child: Column(
            children: [
              _WalletTopRow(
                name: profile.fullName.isEmpty ? 'User' : profile.fullName,
                avatarPath: profile.avatarPath,
                onNotificationTap: () => context.push(RoutePaths.profileNotifications),
              ),
              const SizedBox(height: 26),
              AppCardContainer(
                radius: AppRadius.md,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accentAction,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/wallet/wallet_card_icon.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                AppColors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                walletName,
                                style: AppTextStyles.sectionTitle.copyWith(
                                  fontSize: 20,
                                  height: 28 / 20,
                                ),
                              ),
                              Text(
                                '${state.wallets.length} wallet(s)',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 14,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (firstWalletId.isNotEmpty)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _showEditWalletDialog(
                                  context,
                                  ref,
                                  firstWallet!,
                                );
                                return;
                              }
                              if (value == 'delete') {
                                await ref
                                    .read(walletViewModelProvider.notifier)
                                    .deleteWallet(firstWalletId);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text(l10n.walletEditWallet),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text(l10n.walletDeleteWallet),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.walletBalance,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatRupiah(mainWalletBalance),
                        style: AppTextStyles.screenTitle.copyWith(
                          fontSize: 42 / 1.4,
                          height: 36 / (42 / 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Income',
                            value: _formatRupiah(_num(activeWalletStats['income'])),
                            background: const Color(0xFFF0FDF4),
                            titleColor: const Color(0xFF00A63E),
                            valueColor: const Color(0xFF008236),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Expense',
                            value: _formatRupiah(_num(activeWalletStats['expense'])),
                            background: const Color(0xFFFEF2F2),
                            titleColor: const Color(0xFFE7000B),
                            valueColor: const Color(0xFFC10007),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSecondaryButton(
                      label: l10n.walletManageCategoryLimits,
                      icon: const Icon(
                        Icons.track_changes_rounded,
                        size: 20,
                        color: AppColors.accentAction,
                      ),
                      backgroundColor: const Color(0xFFE0F6FF),
                      foregroundColor: AppColors.accentAction,
                      onPressed: () => context.push(RoutePaths.manageCategory),
                    ),
                    const SizedBox(height: 10),
                    AppSecondaryButton(
                      label: l10n.walletRecurringPlans,
                      icon: const Icon(
                        Icons.repeat_rounded,
                        size: 20,
                        color: AppColors.accentAction,
                      ),
                      backgroundColor: const Color(0xFFEFF4FF),
                      foregroundColor: AppColors.accentAction,
                      onPressed: () => context.push(RoutePaths.recurringTransactions),
                    ),
                    const SizedBox(height: 10),
                    AppPrimaryButton(
                      label: l10n.walletAddIncome,
                      icon: const Icon(Icons.add_card_rounded, color: AppColors.white),
                      onPressed: () => _addIncome(context, ref, state.wallets),
                    ),
                    const SizedBox(height: 10),
                    AppSecondaryButton(
                      label: l10n.walletTransferBetweenWallets,
                      icon: const Icon(
                        Icons.swap_horiz_rounded,
                        size: 20,
                        color: AppColors.accentAction,
                      ),
                      backgroundColor: const Color(0xFFEFF4FF),
                      foregroundColor: AppColors.accentAction,
                      onPressed: state.wallets.length < 2
                          ? null
                          : () => _showTransferDialog(context, ref, state.wallets),
                    ),
                    const SizedBox(height: 17),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 17),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.walletActiveLimits,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF364153),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.walletLimitsAllWallets,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (state.budgetItems.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.walletNoBudgetLimits,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    for (final item in state.budgetItems.take(3)) ...[
                      Row(
                        children: [
                          Text(
                            item['category']?.toString() ?? 'other',
                            style: AppTextStyles.label.copyWith(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_num(item['used']).toStringAsFixed(0)} / ${_num(item['limit']).toStringAsFixed(0)}',
                            style: AppTextStyles.label.copyWith(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: _progress(
                            _num(item['used']),
                            _num(item['limit']),
                          ),
                          minHeight: 8,
                          backgroundColor: AppColors.divider,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentAction,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppCardContainer(
                radius: AppRadius.md,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: AppSecondaryButton(
                  label: l10n.walletAddNewWallet,
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 24,
                    color: AppColors.accentAction,
                  ),
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.accentAction,
                  onPressed: () => context.push(RoutePaths.addWallet),
                ),
              ),
              if (extraWallets.isNotEmpty) ...[
                const SizedBox(height: 18),
                AppCardContainer(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.walletYourWallets,
                        style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < extraWallets.length; i++) ...[
                        _WalletListRow(
                          wallet: extraWallets[i],
                          formatRupiah: _formatRupiah,
                          onAddIncome: () => _addIncome(
                            context,
                            ref,
                            state.wallets,
                            preferredWalletId:
                                extraWallets[i]['id']?.toString() ??
                                extraWallets[i]['_id']?.toString() ??
                                '',
                          ),
                          onEdit: () => _showEditWalletDialog(
                            context,
                            ref,
                            extraWallets[i],
                          ),
                          onDelete: () async {
                            final id = extraWallets[i]['id']?.toString() ?? '';
                            if (id.isEmpty) return;
                            await ref
                                .read(walletViewModelProvider.notifier)
                                .deleteWallet(id);
                          },
                        ),
                        if (i != extraWallets.length - 1)
                          const Divider(height: 16, color: AppColors.divider),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              AppCardContainer(
                radius: AppRadius.md,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.walletRecentTransactions,
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTagFilterChip(
                          context,
                          ref,
                          state,
                          label: 'All',
                          tagValue: '',
                        ),
                        _buildTagFilterChip(
                          context,
                          ref,
                          state,
                          label: 'kerja',
                          tagValue: 'kerja',
                        ),
                        _buildTagFilterChip(
                          context,
                          ref,
                          state,
                          label: 'urgent',
                          tagValue: 'urgent',
                        ),
                        _buildTagFilterChip(
                          context,
                          ref,
                          state,
                          label: 'keluarga',
                          tagValue: 'keluarga',
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showTransactionSearchDialog(context, ref, state),
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: Text(state.transactionQuery.isEmpty
                              ? 'Search'
                              : 'Search: ${state.transactionQuery}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.recentTransactions.isEmpty)
                      Text(
                        l10n.walletNoTransactions,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    for (final tx in state.recentTransactions.take(5))
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (tx['type']?.toString() ?? (tx['is_expense'] == true ? 'expense' : 'income')) == 'income'
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              (tx['type']?.toString() ?? (tx['is_expense'] == true ? 'expense' : 'income')) == 'income'
                                  ? 'IN'
                                  : 'OUT',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx['title']?.toString() ?? 'Transaction',
                                  style: AppTextStyles.label,
                                ),
                                if ((tx['tags'] as List? ?? const []).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      (tx['tags'] as List).join(' • '),
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                if (tx['ai_suggested'] == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'AI suggested${tx['ai_provider'] == null ? '' : ' • ${tx['ai_provider']}'}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: const Color(0xFF1D4ED8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await _editTransaction(context, ref, tx, state.wallets);
                            },
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.accentAction,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final id = tx['id']?.toString() ?? '';
                              if (id.isEmpty) return;
                              await ref
                                  .read(walletViewModelProvider.notifier)
                                  .deleteTransaction(id);
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFC10007),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRupiah(double value) {
    final plain = value.toStringAsFixed(0);
    final chars = plain.split('').reversed.toList();
    final out = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) out.add('.');
      out.add(chars[i]);
    }
    return 'Rp ${out.reversed.join()}';
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _progress(double used, double limit) {
    if (limit <= 0) return 0;
    return (used / limit).clamp(0, 1);
  }

  Future<void> _showEditWalletDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> wallet,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(
      text: wallet['wallet_name']?.toString() ?? '',
    );
    final balanceController = TextEditingController(
      text: _num(wallet['balance']).toStringAsFixed(0),
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.walletEditWallet),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController),
              const SizedBox(height: 8),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final id = wallet['id']?.toString() ?? '';
                if (id.isEmpty) return;
                await ref
                    .read(walletViewModelProvider.notifier)
                    .updateWallet(
                      id: id,
                      name: nameController.text.trim(),
                      balance: _num(balanceController.text),
                      color: wallet['wallet_color']?.toString(),
                    );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addIncome(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> wallets,
    {String? preferredWalletId}
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final aiSettings = ref.read(aiSettingsProvider);
    if (wallets.isEmpty) return;
    final initialWalletId = preferredWalletId?.trim() ?? '';
    final form = await showTransactionFormDialog(
      context,
      wallets: wallets,
      defaultIncome: true,
      lockedType: 'income',
      aiCategorizationEnabled: aiSettings.autoCategorizationEnabled,
      onAiSuggestCategory: (payload) => ref
          .read(backendApiServiceProvider)
          .aiSuggestTransactionCategory(payload),
      onAiParseVoiceTransaction: (transcript, locale) => ref
          .read(backendApiServiceProvider)
          .aiParseTransactionInput(transcript: transcript, locale: locale),
      initial: initialWalletId.isEmpty
          ? null
          : TransactionFormResult(
              walletId: initialWalletId,
              type: 'income',
              amount: 0,
              category: 'Salary',
              source: 'Salary',
              merchantName: 'Income Entry',
              notes: 'Created from app form',
              tags: const ['kerja'],
              date: DateTime.now(),
              isVerified: true,
            ),
    );
    if (form == null) return;

    try {
      final created = await ref.read(walletViewModelProvider.notifier).createTransaction(
            walletId: form.walletId,
            type: form.type,
            category: form.category,
            totalAmount: form.amount,
            source: form.source,
            date: form.date,
            isVerified: form.isVerified,
            merchantName: form.merchantName,
            notes: form.notes,
            tags: form.tags,
          );
      await _submitAiCategoryFeedback(
        ref,
        form,
        transactionId: created['id']?.toString(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.walletIncomeAddedSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.walletIncomeAddFailed}: $e')),
      );
    }
  }

  Future<void> _editTransaction(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> tx,
    List<Map<String, dynamic>> wallets,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final id = tx['id']?.toString() ?? '';
    if (id.isEmpty || wallets.isEmpty) return;

    final initial = TransactionFormResult(
      walletId: tx['wallet_id']?.toString().isNotEmpty == true
          ? tx['wallet_id'].toString()
          : (wallets.first['id']?.toString() ?? wallets.first['_id']?.toString() ?? ''),
      type: tx['type']?.toString() ?? (tx['is_expense'] == true ? 'expense' : 'income'),
      amount: _num(tx['amount']),
      category: tx['category']?.toString() ?? 'General',
      source: tx['source']?.toString() ?? '',
      merchantName: tx['title']?.toString() ?? '',
      notes: tx['notes']?.toString() ?? '',
      tags: (tx['tags'] as List? ?? const []).map((e) => e.toString()).toList(),
      date: DateTime.now(),
      isVerified: true,
    );
    final form = await showTransactionFormDialog(
      context,
      wallets: wallets,
      defaultIncome: initial.type == 'income',
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

    try {
      await ref.read(walletViewModelProvider.notifier).updateTransaction(
            id: id,
            walletId: form.walletId,
            type: form.type,
            category: form.category,
            totalAmount: form.amount,
            source: form.source,
            date: form.date,
            isVerified: form.isVerified,
            merchantName: form.merchantName,
            notes: form.notes,
            tags: form.tags,
          );
      await _submitAiCategoryFeedback(ref, form, transactionId: id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.walletTransactionUpdatedSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.walletTransactionUpdateFailed}: $e')),
      );
    }
  }

  Future<void> _showTransferDialog(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> wallets,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (wallets.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.walletNeedTwoWalletsForTransfer)),
      );
      return;
    }

    var fromWalletId = wallets.first['id']?.toString() ?? wallets.first['_id']?.toString() ?? '';
    var toWalletId = wallets[1]['id']?.toString() ?? wallets[1]['_id']?.toString() ?? '';
    final amountController = TextEditingController();
    final notesController = TextEditingController(text: 'Internal transfer');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.walletTransferBetweenWallets),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: fromWalletId,
                        decoration: InputDecoration(labelText: l10n.walletTransferFrom),
                        items: wallets.map((wallet) {
                          final id = wallet['id']?.toString() ?? wallet['_id']?.toString() ?? '';
                          final name = wallet['wallet_name']?.toString() ?? 'Wallet';
                          return DropdownMenuItem(value: id, child: Text(name));
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            fromWalletId = value;
                            if (toWalletId == fromWalletId) {
                              final fallback = wallets
                                  .map((w) => w['id']?.toString() ?? w['_id']?.toString() ?? '')
                                  .firstWhere((id) => id != fromWalletId, orElse: () => toWalletId);
                              toWalletId = fallback;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: toWalletId,
                        decoration: InputDecoration(labelText: l10n.walletTransferTo),
                        items: wallets.map((wallet) {
                          final id = wallet['id']?.toString() ?? wallet['_id']?.toString() ?? '';
                          final name = wallet['wallet_name']?.toString() ?? 'Wallet';
                          return DropdownMenuItem(value: id, child: Text(name));
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => toWalletId = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n.transactionFormAmount),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(labelText: l10n.scanNotes),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim()) ?? 0;
                    if (amount <= 0 || fromWalletId.isEmpty || toWalletId.isEmpty || fromWalletId == toWalletId) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(l10n.walletTransferInvalidInput)),
                      );
                      return;
                    }
                    try {
                      await ref.read(walletViewModelProvider.notifier).transferBetweenWallets(
                            fromWalletId: fromWalletId,
                            toWalletId: toWalletId,
                            amount: amount,
                            notes: notesController.text.trim(),
                          );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.walletTransferSuccess)),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('${l10n.walletTransferFailed}: $e')),
                      );
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    notesController.dispose();
  }

  Widget _buildTagFilterChip(
    BuildContext context,
    WidgetRef ref,
    WalletScreenState state, {
    required String label,
    required String tagValue,
  }) {
    return FilterChip(
      label: Text(label),
      selected: state.transactionTag == tagValue,
      onSelected: (_) {
        ref.read(walletViewModelProvider.notifier).applyTransactionQuickFilter(
              tag: tagValue,
            );
      },
    );
  }

  Future<void> _showTransactionSearchDialog(
    BuildContext context,
    WidgetRef ref,
    WalletScreenState state,
  ) async {
    final controller = TextEditingController(text: state.transactionQuery);

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
                await ref.read(walletViewModelProvider.notifier).applyTransactionQuickFilter(
                      query: '',
                    );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(walletViewModelProvider.notifier).applyTransactionQuickFilter(
                      query: controller.text.trim(),
                    );
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
    WidgetRef ref,
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

class _WalletTopRow extends StatelessWidget {
  const _WalletTopRow({
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
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeGreeting(context),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontSize: 17,
                  height: 22 / 17,
                ),
              ),
              Text(
                name,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.white,
                  fontSize: 30 / 1.36,
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
                iconColor: AppColors.white,
                backgroundColor: Colors.transparent,
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

ImageProvider _avatarImageProvider(String avatarPath) {
  if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
    return NetworkImage(avatarPath);
  }
  return AssetImage(avatarPath);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.background,
    required this.titleColor,
    required this.valueColor,
  });

  final String title;
  final String value;
  final Color background;
  final Color titleColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: titleColor,
              fontSize: 12,
              height: 16 / 12,
            ),
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
                  style: AppTextStyles.body.copyWith(
                    color: valueColor,
                    fontSize: 24 / 1.5,
                    height: 24 / (24 / 1.5),
                    fontWeight: FontWeight.w700,
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

class _WalletListRow extends StatelessWidget {
  const _WalletListRow({
    required this.wallet,
    required this.formatRupiah,
    required this.onAddIncome,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> wallet;
  final String Function(double value) formatRupiah;
  final VoidCallback onAddIncome;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = wallet['wallet_name']?.toString() ?? 'Wallet';
    final balance = _parseNumber(wallet['balance']);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.label),
              const SizedBox(height: 2),
              Text(
                formatRupiah(balance),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (value) {
            if (value == 'add_income') {
              onAddIncome();
              return;
            }
            if (value == 'edit') {
              onEdit();
              return;
            }
            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'add_income',
              child: Text(AppLocalizations.of(context)!.walletAddIncome),
            ),
            PopupMenuItem<String>(
              value: 'edit',
              child: Text(AppLocalizations.of(context)!.walletEditWallet),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text(AppLocalizations.of(context)!.walletDeleteWallet),
            ),
          ],
        ),
      ],
    );
  }

  double _parseNumber(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
