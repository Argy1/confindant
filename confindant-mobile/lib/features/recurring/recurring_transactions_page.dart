import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringTransactionsPage extends ConsumerStatefulWidget {
  const RecurringTransactionsPage({super.key});

  @override
  ConsumerState<RecurringTransactionsPage> createState() => _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState extends ConsumerState<RecurringTransactionsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _wallets = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    AppIconButtonCircle(
                      icon: Icons.arrow_back_rounded,
                      iconColor: AppColors.white,
                      backgroundColor: AppColors.white.withValues(alpha: 0.18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recurring Transactions',
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    AppIconButtonCircle(
                      icon: Icons.add_rounded,
                      iconColor: AppColors.white,
                      backgroundColor: AppColors.white.withValues(alpha: 0.18),
                      onPressed: _wallets.isEmpty ? null : _showCreateDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _items.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                itemCount: _items.length,
                                separatorBuilder: (_, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) => _buildItem(_items[index]),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return AppCardContainer(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat_rounded, size: 40, color: AppColors.accentAction),
          const SizedBox(height: 8),
          Text(
            'Belum ada recurring transaction.',
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan jadwal pemasukan/pengeluaran otomatis agar transaksi tercatat rutin.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: 'Tambah Recurring',
            onPressed: _wallets.isEmpty ? null : _showCreateDialog,
            icon: const Icon(Icons.add_rounded, color: AppColors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? item['_id']?.toString() ?? '';
    final active = item['active'] == true;
    final amount = (item['amount'] is num)
        ? (item['amount'] as num).toDouble()
        : double.tryParse(item['amount']?.toString() ?? '') ?? 0;
    final type = item['type']?.toString() ?? 'expense';
    final frequency = item['frequency']?.toString() ?? 'monthly';
    final interval = item['interval']?.toString() ?? '1';
    final nextRun = item['next_run_at']?.toString() ?? '-';
    final category = item['category']?.toString() ?? 'General';

    return AppCardContainer(
      radius: AppRadius.md,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: type == 'income' ? const Color(0xFFEAFBF1) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  type == 'income' ? 'INCOME' : 'EXPENSE',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: type == 'income' ? const Color(0xFF008236) : const Color(0xFFC10007),
                  ),
                ),
              ),
              const Spacer(),
              Switch(
                value: active,
                onChanged: (_) => _toggleActive(id, active),
              ),
              IconButton(
                onPressed: () => _showCreateDialog(existing: item),
                icon: const Icon(Icons.edit_outlined, color: AppColors.accentAction),
              ),
              IconButton(
                onPressed: () => _delete(id),
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC10007)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            category,
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp ${amount.toStringAsFixed(0)}  |  Every $interval $frequency',
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 3),
          Text(
            'Next run: $nextRun',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          if ((item['last_error_code']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Last error: ${item['last_error_code']}',
              style: AppTextStyles.caption.copyWith(color: const Color(0xFFC10007)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(backendApiServiceProvider);
      final wallets = await api.wallets();
      final items = await api.recurringTransactions();
      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recurring transactions: $e')),
      );
    }
  }

  Future<void> _toggleActive(String id, bool current) async {
    if (id.isEmpty) return;
    try {
      await ref.read(backendApiServiceProvider).updateRecurringTransaction(id, {
        'active': !current,
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update recurring status: $e')),
      );
    }
  }

  Future<void> _delete(String id) async {
    if (id.isEmpty) return;
    try {
      await ref.read(backendApiServiceProvider).deleteRecurringTransaction(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete recurring transaction: $e')),
      );
    }
  }

  Future<void> _showCreateDialog({Map<String, dynamic>? existing}) async {
    if (_wallets.isEmpty) return;
    final isEdit = existing != null;
    final existingWalletId = existing?['wallet_id']?.toString();
    final existingType = existing?['type']?.toString();
    final existingFrequency = existing?['frequency']?.toString();
    final existingStartRaw = existing?['start_date']?.toString();
    final existingId = existing?['id']?.toString() ?? existing?['_id']?.toString() ?? '';
    final existingAmountRaw = existing?['amount']?.toString();
    final existingIntervalRaw = existing?['interval']?.toString();

    final walletId = ValueNotifier<String>(
      (existingWalletId?.isNotEmpty == true)
          ? existingWalletId!
          : (_wallets.first['id']?.toString() ?? _wallets.first['_id']?.toString() ?? ''),
    );
    final type = ValueNotifier<String>(
      (existingType == 'income' || existingType == 'expense') ? existingType! : 'expense',
    );
    final frequency = ValueNotifier<String>(
      (existingFrequency == 'daily' || existingFrequency == 'weekly' || existingFrequency == 'monthly')
          ? existingFrequency!
          : 'monthly',
    );
    final interval = TextEditingController(text: existingIntervalRaw?.isNotEmpty == true ? existingIntervalRaw : '1');
    final amount = TextEditingController(text: existingAmountRaw ?? '');
    final category = TextEditingController(text: existing?['category']?.toString() ?? 'General');
    final source = TextEditingController(text: existing?['source']?.toString() ?? 'Other');
    final notes = TextEditingController(text: existing?['notes']?.toString() ?? 'Created from recurring plan');
    DateTime startDate = DateTime.tryParse(existingStartRaw ?? '') ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Recurring Transaction' : 'Create Recurring Transaction'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: walletId.value,
                        decoration: const InputDecoration(labelText: 'Wallet'),
                        items: _wallets.map((w) {
                          final id = w['id']?.toString() ?? w['_id']?.toString() ?? '';
                          final name = w['wallet_name']?.toString() ?? 'Wallet';
                          return DropdownMenuItem(value: id, child: Text(name));
                        }).toList(),
                        onChanged: (v) => walletId.value = v ?? walletId.value,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: type.value,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(value: 'income', child: Text('Income')),
                          DropdownMenuItem(value: 'expense', child: Text('Expense')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setDialogState(() => type.value = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Amount'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: source,
                        decoration: const InputDecoration(labelText: 'Source (optional)'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: frequency.value,
                        decoration: const InputDecoration(labelText: 'Frequency'),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setDialogState(() => frequency.value = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: interval,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Interval'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Start date'),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDate: startDate,
                              );
                              if (picked == null) return;
                              setDialogState(() => startDate = picked);
                            },
                            child: Text(
                              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notes,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final parsedAmount = double.tryParse(amount.text.trim()) ?? 0;
                    final parsedInterval = int.tryParse(interval.text.trim()) ?? 1;
                    if (walletId.value.isEmpty || parsedAmount <= 0 || parsedInterval <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill valid wallet, amount, and interval')),
                      );
                      return;
                    }
                    try {
                      final payload = {
                        'wallet_id': walletId.value,
                        'type': type.value,
                        'amount': parsedAmount,
                        'category': category.text.trim().isEmpty ? 'General' : category.text.trim(),
                        'source': source.text.trim(),
                        'notes': notes.text.trim(),
                        'frequency': frequency.value,
                        'interval': parsedInterval,
                        'start_date': startDate.toIso8601String(),
                        'active': existing?['active'] == true ? true : true,
                        'is_verified': true,
                      };
                      if (isEdit) {
                        await ref
                            .read(backendApiServiceProvider)
                            .updateRecurringTransaction(existingId, payload);
                      } else {
                        await ref
                            .read(backendApiServiceProvider)
                            .createRecurringTransaction(payload);
                      }
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      await _load();
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? 'Failed to update recurring transaction: $e'
                                : 'Failed to create recurring transaction: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    interval.dispose();
    amount.dispose();
    category.dispose();
    source.dispose();
    notes.dispose();
  }
}
