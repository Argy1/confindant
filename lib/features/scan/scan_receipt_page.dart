import 'dart:io';

import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ScanReceiptPage extends ConsumerWidget {
  const ScanReceiptPage({super.key, this.initialImagePath});

  final String? initialImagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 88, 30, 28),
            child: Column(
              children: [
                AppCardContainer(
                  radius: AppRadius.lg,
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildReceiptPreview(),
                  ),
                ),
                const SizedBox(height: 26),
                AppCardContainer(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt Details',
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 20,
                          height: 28 / 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vendor: Store Name\nCategory: Shopping\nTotal: Rp 55.000',
                        style: AppTextStyles.body.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Items:\n- Product 1 x2 = 30.000\n- Product 2 x1 = 25.000',
                        style: AppTextStyles.caption.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: AppSecondaryButton(
                              label: 'Cancel',
                              backgroundColor: const Color(0xFFE5E7EB),
                              foregroundColor: const Color(0xFF364153),
                              onPressed: context.pop,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'Save',
                              icon: const Icon(
                                Icons.check_rounded,
                                color: AppColors.white,
                                size: 18,
                              ),
                              onPressed: () => _saveReceipt(context, ref),
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
      ),
    );
  }

  Widget _buildReceiptPreview() {
    final path = initialImagePath;
    if (path != null && path.isNotEmpty) {
      return Image.file(File(path), height: 280, width: 310, fit: BoxFit.cover);
    }

    return Image.asset(
      'assets/images/scan/receipt_preview.jpg',
      height: 280,
      width: 310,
      fit: BoxFit.cover,
    );
  }

  Future<void> _saveReceipt(BuildContext context, WidgetRef ref) async {
    final walletState = ref.read(walletViewModelProvider);
    final walletId = walletState.wallets.isNotEmpty
        ? (walletState.wallets.first['id']?.toString() ??
              walletState.wallets.first['_id']?.toString() ??
              '')
        : '';

    if (walletId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create wallet first.')),
      );
      return;
    }

    await ref
        .read(backendApiServiceProvider)
        .uploadReceipt(
          filePath: initialImagePath,
          fields: {
            'wallet_id': walletId,
            'type': 'expense',
            'category': 'Shopping',
            'total_amount': 55000,
            'date': DateTime.now().toIso8601String(),
            'merchant_name': 'Store Name',
            'notes': 'Uploaded from scan receipt page',
            'items': [
              {
                'name': 'Product 1',
                'qty': 2,
                'price': 15000,
                'subtotal': 30000,
              },
              {
                'name': 'Product 2',
                'qty': 1,
                'price': 25000,
                'subtotal': 25000,
              },
            ],
          },
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Receipt saved to backend.')));
    if (Navigator.of(context).canPop()) {
      context.pop();
    }
  }
}
