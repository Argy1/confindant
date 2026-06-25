import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/management_models.dart';
import 'package:confindant/features/org/models/org_models.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/presentation/widgets/account_picker.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrgRecurringPage extends ConsumerStatefulWidget {
  const OrgRecurringPage({super.key});

  @override
  ConsumerState<OrgRecurringPage> createState() => _OrgRecurringPageState();
}

class _OrgRecurringPageState extends ConsumerState<OrgRecurringPage> {
  List<RecurringOrgData> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  bool _canWrite(String? orgId) {
    if (orgId == null) return false;
    final orgs = ref.read(myOrganizationsProvider).valueOrNull ?? const [];
    for (final Organization o in orgs) {
      if (o.id == orgId) return o.canWrite;
    }
    return false;
  }

  Future<void> _load() async {
    final orgId = ref.read(activeOrgIdProvider);
    if (orgId == null) return;
    setState(() => _loading = true);
    try {
      final raw = await ref
          .read(backendApiServiceProvider)
          .orgRecurringList(orgId);
      if (!mounted) return;
      setState(() => _items = raw.map(RecurringOrgData.fromJson).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);
    final canWrite = _canWrite(orgId);

    return OrgScaffold(
      title: 'Jurnal Berulang',
      current: OrgNavItem.more,
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.blue900,
              foregroundColor: Colors.white,
              onPressed: () => _openForm(context, orgId: orgId!),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah'),
            )
          : null,
      child: orgId == null
          ? const Center(child: Text('Pilih organisasi terlebih dahulu.'))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.repeat_rounded,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada jurnal berulang.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (canWrite) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  _openForm(context, orgId: orgId),
                              child: const Text('Tambah sekarang'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _RecurringCard(
                          item: _items[i],
                          canWrite: canWrite,
                          onEdit: () => _openForm(
                            context,
                            orgId: orgId,
                            existing: _items[i],
                          ),
                          onToggle: () => _toggle(orgId, _items[i]),
                          onRunNow: () => _runNow(orgId, _items[i]),
                          onDelete: () => _delete(orgId, _items[i]),
                        ),
                      ),
                    ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    required String orgId,
    RecurringOrgData? existing,
  }) async {
    final accounts = await ref.read(orgDataSourceProvider).accounts(orgId);
    if (!context.mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RecurringForm(
        accounts: accounts,
        existing: existing,
      ),
    );
    if (result == null || !mounted) return;

    try {
      if (existing == null) {
        await ref
            .read(backendApiServiceProvider)
            .orgRecurringCreate(orgId, result);
      } else {
        await ref
            .read(backendApiServiceProvider)
            .orgRecurringUpdate(orgId, existing.id, result);
      }
      await _load();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  Future<void> _toggle(String orgId, RecurringOrgData item) async {
    try {
      await ref.read(backendApiServiceProvider).orgRecurringUpdate(
        orgId,
        item.id,
        {'active': !item.active},
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    }
  }

  Future<void> _runNow(String orgId, RecurringOrgData item) async {
    try {
      await ref
          .read(backendApiServiceProvider)
          .orgRecurringRun(orgId, item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jurnal berhasil dibuat.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    }
  }

  Future<void> _delete(String orgId, RecurringOrgData item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus jadwal berulang?'),
        content: Text('Hapus "${item.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref
          .read(backendApiServiceProvider)
          .orgRecurringDelete(orgId, item.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    }
  }
}

// ---- Card ----------------------------------------------------------------

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.item,
    required this.canWrite,
    required this.onEdit,
    required this.onToggle,
    required this.onRunNow,
    required this.onDelete,
  });

  final RecurringOrgData item;
  final bool canWrite;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onRunNow;
  final VoidCallback onDelete;

  String _freqLabel(String freq, int interval) {
    switch (freq) {
      case 'daily':
        return interval == 1 ? 'Harian' : 'Setiap $interval hari';
      case 'weekly':
        return interval == 1 ? 'Mingguan' : 'Setiap $interval minggu';
      default:
        return interval == 1 ? 'Bulanan' : 'Setiap $interval bulan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _freqLabel(item.frequency, item.interval),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _AmountBadge(amount: item.amount),
                if (canWrite)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'toggle') onToggle();
                      if (v == 'run') onRunNow();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'run',
                        child: Text('Jalankan Sekarang'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          item.active ? 'Nonaktifkan' : 'Aktifkan',
                        ),
                      ),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Hapus',
                          style: TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _AccountRow(
              debitCode: item.debitAccountCode,
              debitName: item.debitAccountName,
              creditCode: item.creditAccountCode,
              creditName: item.creditAccountName,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _StatusChip(active: item.active),
                const SizedBox(width: 8),
                if (item.nextRunAt != null)
                  Text(
                    'Berikutnya: ${_shortDate(item.nextRunAt!)}',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const Spacer(),
                Text(
                  '${item.totalRuns}x dijalankan',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _AmountBadge extends StatelessWidget {
  const _AmountBadge({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    final formatted = amount >= 1000000
        ? '${(amount / 1000000).toStringAsFixed(1)}jt'
        : amount >= 1000
            ? '${(amount / 1000).toStringAsFixed(0)}rb'
            : amount.toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        'Rp $formatted',
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.blue900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    this.debitCode,
    this.debitName,
    this.creditCode,
    this.creditName,
  });
  final String? debitCode;
  final String? debitName;
  final String? creditCode;
  final String? creditName;

  @override
  Widget build(BuildContext context) {
    String label(String? code, String? name) {
      if (code != null && name != null) return '$code · $name';
      return name ?? code ?? '-';
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'D: ${label(debitCode, debitName)}',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'K: ${label(creditCode, creditName)}',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Aktif' : 'Nonaktif',
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: active
              ? const Color(0xFF15803D)
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ---- Add/Edit Form -------------------------------------------------------

class _RecurringForm extends StatefulWidget {
  const _RecurringForm({required this.accounts, this.existing});

  final List<OrgAccount> accounts;
  final RecurringOrgData? existing;

  @override
  State<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends State<_RecurringForm> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _intervalCtrl;
  late String _frequency;
  late DateTime _startDate;
  DateTime? _endDate;
  OrgAccount? _debitAccount;
  OrgAccount? _creditAccount;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(0) : '',
    );
    _intervalCtrl = TextEditingController(
      text: e != null ? e.interval.toString() : '1',
    );
    _frequency = e?.frequency ?? 'monthly';
    _startDate = DateTime.tryParse(e?.startDate ?? '') ?? DateTime.now();
    _endDate = e?.endDate != null ? DateTime.tryParse(e!.endDate!) : null;

    // Pre-select accounts by id
    if (e != null) {
      _debitAccount = widget.accounts
          .where((a) => a.id == e.debitAccountId)
          .firstOrNull;
      _creditAccount = widget.accounts
          .where((a) => a.id == e.creditAccountId)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEdit ? 'Edit Jurnal Berulang' : 'Tambah Jurnal Berulang',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Deskripsi'),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frekuensi'),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Harian')),
                DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
                DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _frequency = v);
              },
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _intervalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Interval',
                hintText: '1 = setiap periode',
              ),
            ),
            const SizedBox(height: 10),

            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickDate(isEnd: false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Mulai',
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(_fmt(_startDate)),
              ),
            ),
            const SizedBox(height: 10),

            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickDate(isEnd: true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Selesai (opsional)',
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(
                  _endDate != null ? _fmt(_endDate!) : 'Tidak dibatasi',
                ),
              ),
            ),
            if (_endDate != null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _endDate = null),
                  child: const Text('Hapus tanggal selesai'),
                ),
              ),
            ],
            const SizedBox(height: 10),

            _AccountPickerTile(
              label: 'Akun Debit',
              account: _debitAccount,
              onTap: () => _pickAccount(isDebit: true),
            ),
            const SizedBox(height: 10),

            _AccountPickerTile(
              label: 'Akun Kredit',
              account: _creditAccount,
              onTap: () => _pickAccount(isDebit: false),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submit,
                child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final initial = isEnd ? (_endDate ?? _startDate) : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isEnd) {
        _endDate = picked;
      } else {
        _startDate = picked;
      }
    });
  }

  Future<void> _pickAccount({required bool isDebit}) async {
    final picked = await pickAccount(
      context,
      accounts: widget.accounts,
      title: isDebit ? 'Pilih Akun Debit' : 'Pilih Akun Kredit',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isDebit) {
        _debitAccount = picked;
      } else {
        _creditAccount = picked;
      }
    });
  }

  void _submit() {
    final desc = _descCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final interval = int.tryParse(_intervalCtrl.text.trim()) ?? 1;

    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi tidak boleh kosong.')),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0.')),
      );
      return;
    }
    if (_debitAccount == null || _creditAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun debit dan kredit.')),
      );
      return;
    }

    Navigator.of(context).pop({
      'description': desc,
      'amount': amount,
      'frequency': _frequency,
      'interval': interval,
      'start_date': _startDate.toIso8601String().substring(0, 10),
      'end_date': _endDate?.toIso8601String().substring(0, 10),
      'debit_account_id': _debitAccount!.id,
      'credit_account_id': _creditAccount!.id,
    });
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _AccountPickerTile extends StatelessWidget {
  const _AccountPickerTile({
    required this.label,
    required this.account,
    required this.onTap,
  });
  final String label;
  final OrgAccount? account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
        ),
        child: account == null
            ? Text(
                'Pilih akun...',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : Text(
                '${account!.code} · ${account!.name}',
                style: AppTextStyles.caption,
              ),
      ),
    );
  }
}
