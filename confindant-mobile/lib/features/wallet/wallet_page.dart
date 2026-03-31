import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletViewModelProvider);
    final firstWallet = state.wallets.isNotEmpty ? state.wallets.first : null;
    final firstWalletId = firstWallet?['id']?.toString() ?? '';
    final walletName = firstWallet?['wallet_name']?.toString() ?? 'Main Wallet';

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.appBackground),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(31, 62, 31, 140),
          child: Column(
            children: [
              _WalletTopRow(onNotificationTap: () {}),
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
                            itemBuilder: (context) => const [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text('Edit wallet'),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Delete wallet'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Balance',
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
                        _formatRupiah(state.balance),
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
                            value: _formatRupiah(state.income),
                            background: const Color(0xFFF0FDF4),
                            titleColor: const Color(0xFF00A63E),
                            valueColor: const Color(0xFF008236),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Expense',
                            value: _formatRupiah(state.expense),
                            background: const Color(0xFFFEF2F2),
                            titleColor: const Color(0xFFE7000B),
                            valueColor: const Color(0xFFC10007),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSecondaryButton(
                      label: 'Manage Category Limits',
                      icon: const Icon(
                        Icons.track_changes_rounded,
                        size: 20,
                        color: AppColors.accentAction,
                      ),
                      backgroundColor: const Color(0xFFE0F6FF),
                      foregroundColor: AppColors.accentAction,
                      onPressed: () => context.push(RoutePaths.manageCategory),
                    ),
                    const SizedBox(height: 17),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 17),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Active Limits:',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF364153),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (state.budgetItems.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No budget limits set yet.',
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
                  label: 'Add New Wallet',
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
              const SizedBox(height: 18),
              AppCardContainer(
                radius: AppRadius.md,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    if (state.recentTransactions.isEmpty)
                      Text(
                        'No transactions yet.',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    for (final tx in state.recentTransactions.take(5))
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tx['title']?.toString() ?? 'Transaction',
                              style: AppTextStyles.label,
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
          title: const Text('Edit Wallet'),
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
}

class _WalletTopRow extends StatelessWidget {
  const _WalletTopRow({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage('assets/avatars/wallet_avatar.png'),
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning!',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontSize: 17,
                  height: 22 / 17,
                ),
              ),
              Text(
                'Kennedy',
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.white,
                  fontSize: 30 / 1.36,
                ),
              ),
            ],
          ),
        ),
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
      ],
    );
  }
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
      height: 68,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: valueColor,
              fontSize: 24 / 1.5,
              height: 24 / (24 / 1.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
