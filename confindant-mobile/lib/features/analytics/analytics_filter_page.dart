import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/analytics/presentation/view_models/analytics_view_model.dart';
import 'package:confindant/features/analytics/presentation/view_models/advanced_analytics_view_model.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnalyticsFilterPage extends ConsumerStatefulWidget {
  const AnalyticsFilterPage({super.key});

  @override
  ConsumerState<AnalyticsFilterPage> createState() =>
      _AnalyticsFilterPageState();
}

class _AnalyticsFilterPageState extends ConsumerState<AnalyticsFilterPage> {
  late TextEditingController _from;
  late TextEditingController _to;
  String _wallet = 'All Wallets';
  String _walletId = '';
  String _category = 'All Categories';

  @override
  void initState() {
    super.initState();
    final f = ref.read(advancedAnalyticsProvider);
    _from = TextEditingController(text: f.fromDateLabel);
    _to = TextEditingController(text: f.toDateLabel);
    _wallet = f.wallet;
    _walletId = f.walletId;
    _category = f.category;
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletViewModelProvider).wallets;
    final analyticsData = ref.watch(analyticsViewModelProvider).data;
    final categorySet = <String>{'All Categories'};
    categorySet.addAll(
      analyticsData?.categoryBreakdown.map((e) => e.label) ?? const <String>[],
    );
    categorySet.addAll(
      ref
          .watch(walletViewModelProvider)
          .budgets
          .map((e) => e['category']?.toString() ?? '')
          .where((e) => e.isNotEmpty),
    );
    final categories = categorySet.toList();

    final walletItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: '', child: Text('All Wallets')),
      ...wallets.map((wallet) {
        final id =
            wallet['id']?.toString() ?? wallet['_id']?.toString() ?? '';
        final name = wallet['wallet_name']?.toString() ?? 'Wallet';
        return DropdownMenuItem(value: id, child: Text(name));
      }),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Text(
                      'Analytics Filter',
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const LanguageSwitcherButton(
                      iconColor: AppColors.white,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppCardContainer(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _from,
                        labelText: 'From Date',
                        hintText: 'YYYY-MM-DD',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _to,
                        labelText: 'To Date',
                        hintText: 'YYYY-MM-DD',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _walletId,
                        items: walletItems,
                        onChanged: (v) {
                          final selected = wallets.firstWhere(
                            (wallet) =>
                                (wallet['id']?.toString() ??
                                    wallet['_id']?.toString() ??
                                    '') ==
                                (v ?? ''),
                            orElse: () => const <String, dynamic>{},
                          );
                          setState(() {
                            _walletId = v ?? '';
                            _wallet = _walletId.isEmpty
                                ? 'All Wallets'
                                : (selected['wallet_name']?.toString() ?? 'Wallet');
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Wallet'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        items: categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _category = v ?? _category),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppPrimaryButton(
                        label: 'Apply Filter',
                        onPressed: () {
                          ref
                              .read(advancedAnalyticsProvider.notifier)
                              .updateFilter(
                                fromDateLabel: _from.text.trim(),
                                toDateLabel: _to.text.trim(),
                                wallet: _wallet,
                                walletId: _walletId,
                                category: _category,
                              );
                          ref.read(analyticsViewModelProvider.notifier).retry();
                          context.pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
