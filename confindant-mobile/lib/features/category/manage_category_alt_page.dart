import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/category/widgets/category_ui.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManageCategoryAltPage extends ConsumerStatefulWidget {
  const ManageCategoryAltPage({super.key});

  @override
  ConsumerState<ManageCategoryAltPage> createState() =>
      _ManageCategoryAltPageState();
}

class _ManageCategoryAltPageState extends ConsumerState<ManageCategoryAltPage> {
  final _categoryController = TextEditingController();
  final _limitController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletViewModelProvider);

    return CategoryModalShell(
      title: 'Category Spending Limits',
      subtitle: 'savings',
      onClose: context.pop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryLimitFormCard(
            categoryController: _categoryController,
            limitController: _limitController,
            onAddTap: _addLimitFromInput,
          ),
          const SizedBox(height: 24),
          Text(
            'Current Limits',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...state.budgetItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFA6E1FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['category']?.toString() ?? 'category',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 32 / 2,
                            ),
                          ),
                          Text(
                            'Limit: Rp ${item['limit']}',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final id =
                            item['id']?.toString() ??
                            item['_id']?.toString() ??
                            '';
                        if (id.isEmpty) return;
                        ref
                            .read(walletViewModelProvider.notifier)
                            .deleteBudget(id);
                      },
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFFF2F2F),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppPrimaryButton(
            label: 'Save Limits',
            icon: const Icon(
              Icons.check_rounded,
              color: AppColors.white,
              size: 20,
            ),
            onPressed: _addLimitFromInput,
          ),
        ],
      ),
    );
  }

  Future<void> _addLimitFromInput() async {
    final category = _categoryController.text.trim();
    final limit = double.tryParse(_limitController.text.trim()) ?? 0;
    if (category.isEmpty || limit <= 0) return;

    await ref
        .read(walletViewModelProvider.notifier)
        .createBudget(category: category, limitAmount: limit);

    _categoryController.clear();
    _limitController.clear();
  }
}
