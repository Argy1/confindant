import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/category/widgets/category_ui.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManageCategoryPage extends ConsumerStatefulWidget {
  const ManageCategoryPage({super.key});

  @override
  ConsumerState<ManageCategoryPage> createState() => _ManageCategoryPageState();
}

class _ManageCategoryPageState extends ConsumerState<ManageCategoryPage> {
  final _categoryController = TextEditingController();
  final _limitController = TextEditingController();
  String? _editingBudgetId;

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
            onAddTap: _addLimit,
          ),
          const SizedBox(height: 24),
          if (state.budgets.isEmpty)
            SizedBox(
              width: double.infinity,
              child: Text(
                'No category limits set. Add one above!',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFF99A1AF),
                  fontSize: 16,
                  height: 24 / 16,
                ),
              ),
            ),
          for (final item in state.budgets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item['category']} - ${item['limit_amount']}',
                      style: AppTextStyles.body,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final id = item['id']?.toString() ?? '';
                      if (id.isEmpty) return;
                      await ref
                          .read(walletViewModelProvider.notifier)
                          .deleteBudget(id);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFC10007),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editLimit(item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: _editingBudgetId == null ? 'Save Limits' : 'Update Limit',
            icon: const Icon(
              Icons.check_rounded,
              color: AppColors.white,
              size: 20,
            ),
            onPressed: _addLimit,
          ),
        ],
      ),
    );
  }

  Future<void> _addLimit() async {
    final category = _categoryController.text.trim();
    final limit = double.tryParse(_limitController.text.trim()) ?? 0;
    if (category.isEmpty || limit <= 0) return;

    final vm = ref.read(walletViewModelProvider.notifier);
    final editingId = _editingBudgetId;
    if (editingId == null) {
      await vm.createBudget(category: category, limitAmount: limit);
    } else {
      await vm.updateBudget(
        id: editingId,
        category: category,
        limitAmount: limit,
      );
    }

    _categoryController.clear();
    _limitController.clear();
    setState(() => _editingBudgetId = null);
  }

  void _editLimit(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;

    _categoryController.text = item['category']?.toString() ?? '';
    _limitController.text = item['limit_amount']?.toString() ?? '';
    setState(() => _editingBudgetId = id);
  }
}
