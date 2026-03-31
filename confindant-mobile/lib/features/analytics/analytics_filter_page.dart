import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/analytics/presentation/view_models/advanced_analytics_view_model.dart';
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
  String _category = 'All Categories';

  @override
  void initState() {
    super.initState();
    final f = ref.read(advancedAnalyticsProvider);
    _from = TextEditingController(text: f.fromDateLabel);
    _to = TextEditingController(text: f.toDateLabel);
    _wallet = f.wallet;
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
                        initialValue: _wallet,
                        items: const [
                          DropdownMenuItem(
                            value: 'All Wallets',
                            child: Text('All Wallets'),
                          ),
                          DropdownMenuItem(
                            value: 'Main Wallet',
                            child: Text('Main Wallet'),
                          ),
                          DropdownMenuItem(
                            value: 'Travel Wallet',
                            child: Text('Travel Wallet'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _wallet = v ?? _wallet),
                        decoration: const InputDecoration(labelText: 'Wallet'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        items: const [
                          DropdownMenuItem(
                            value: 'All Categories',
                            child: Text('All Categories'),
                          ),
                          DropdownMenuItem(value: 'Food', child: Text('Food')),
                          DropdownMenuItem(
                            value: 'Shopping',
                            child: Text('Shopping'),
                          ),
                          DropdownMenuItem(
                            value: 'Transport',
                            child: Text('Transport'),
                          ),
                        ],
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
                                category: _category,
                              );
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
