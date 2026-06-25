import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/management_models.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/presentation/widgets/account_picker.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _statusLabels = {
  'open': 'Belum dibayar',
  'partial': 'Sebagian',
  'settled': 'Lunas',
  'written_off': 'Dihapus',
};

class OrgReceivablesPayablesPage extends ConsumerStatefulWidget {
  const OrgReceivablesPayablesPage({super.key});

  @override
  ConsumerState<OrgReceivablesPayablesPage> createState() =>
      _OrgReceivablesPayablesPageState();
}

class _OrgReceivablesPayablesPageState
    extends ConsumerState<OrgReceivablesPayablesPage> {
  String _tab = 'receivable';

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);
    final canWrite = ref.watch(orgCanWriteProvider(orgId));

    return OrgScaffold(
      title: 'Piutang & Hutang',
      current: OrgNavItem.more,
      floatingActionButton: canWrite && orgId != null
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.blue900,
              foregroundColor: Colors.white,
              onPressed: () => _showAddSheet(orgId, _tab),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah'),
            )
          : null,
      child: orgId == null
          ? const Center(child: Text('Belum ada organisasi'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _tabBtn('Piutang', 'receivable'),
                        _tabBtn('Hutang', 'payable'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ref
                      .watch(orgReceivablesPayablesProvider(
                          (orgId: orgId, type: _tab)))
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: OutlinedButton(
                            onPressed: () => ref.invalidate(
                              orgReceivablesPayablesProvider(
                                  (orgId: orgId, type: _tab)),
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ),
                        data: (items) => _list(orgId, items, canWrite),
                      ),
                ),
              ],
            ),
    );
  }

  Widget _tabBtn(String label, String value) {
    final active = _tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.blue900 : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(
      String orgId, List<ReceivablePayableData> items, bool canWrite) {
    final totalOutstanding =
        items.fold<double>(0, (s, i) => s + i.outstandingAmount);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
            orgReceivablesPayablesProvider((orgId: orgId, type: _tab)));
        await ref.read(
            orgReceivablesPayablesProvider((orgId: orgId, type: _tab)).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      size: 18, color: Color(0xFFD97706)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total ${_tab == 'receivable' ? 'Piutang' : 'Hutang'} Belum Selesai',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textTertiary),
                      ),
                      Text(
                        formatOrgRupiah(totalOutstanding),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  'Belum ada ${_tab == 'receivable' ? 'piutang' : 'hutang'}',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textTertiary),
                ),
              ),
            )
          else
            ...items.map((it) => _itemCard(orgId, it, canWrite)),
        ],
      ),
    );
  }

  Widget _itemCard(
      String orgId, ReceivablePayableData it, bool canWrite) {
    final pct = it.originalAmount > 0
        ? (it.settledAmount / it.originalAmount).clamp(0.0, 1.0)
        : 0.0;
    final (badgeBg, badgeFg) = switch (it.status) {
      'settled' => (const Color(0xFFECFDF5), const Color(0xFF047857)),
      'partial' => (const Color(0xFFFFFBEB), const Color(0xFFB45309)),
      _ => (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
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
                      it.partyName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${it.category ?? '—'} · ${orgFormatDate(it.issuedDate)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabels[it.status] ?? it.status,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeFg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0xFFEFF1F5),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.blue600),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Terbayar ${formatOrgRupiah(it.settledAmount)}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textTertiary),
                ),
              ),
              Text(
                'Sisa ${formatOrgRupiah(it.outstandingAmount)}',
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (canWrite && it.status != 'settled') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _showSettleSheet(orgId, it),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Catat Pelunasan'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddSheet(String orgId, String type) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddSheet(orgId: orgId, type: type),
    );
  }

  void _showSettleSheet(String orgId, ReceivablePayableData item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SettleSheet(orgId: orgId, item: item),
    );
  }
}

class _AddSheet extends ConsumerStatefulWidget {
  const _AddSheet({required this.orgId, required this.type});

  final String orgId;
  final String type;

  @override
  ConsumerState<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends ConsumerState<_AddSheet> {
  final _party = TextEditingController();
  final _category = TextEditingController();
  OrgAccount? _account;
  OrgAccount? _counter;
  String _amount = '';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _party.dispose();
    _category.dispose();
    super.dispose();
  }

  bool get _isReceivable => widget.type == 'receivable';

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_party.text.trim().isEmpty) return _toast('Isi nama pihak');
    if (_account == null) return _toast('Pilih akun kontrol');
    if ((double.tryParse(_amount) ?? 0) <= 0) return _toast('Nominal harus > 0');
    setState(() => _saving = true);
    try {
      await ref
          .read(orgDataSourceProvider)
          .createReceivablePayable(widget.orgId, {
        'type': widget.type,
        'party_name': _party.text.trim(),
        'category': _category.text.trim().isEmpty ? null : _category.text.trim(),
        'account_id': _account!.id,
        'counter_account_id': _counter?.id,
        'original_amount': double.parse(_amount),
        'issued_date': _dateStr,
      });
      ref.invalidate(orgReceivablesPayablesProvider(
          (orgId: widget.orgId, type: widget.type)));
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast(_isReceivable ? 'Piutang dibuat' : 'Hutang dibuat');
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final orgId = widget.orgId;
    final accounts =
        ref.watch(orgAccountsProvider(orgId)).valueOrNull ?? const [];

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tambah ${_isReceivable ? 'Piutang' : 'Hutang'}',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            AppTextField(
              hintText: _isReceivable ? 'mis. dr. Aria' : 'mis. Vendor X',
              labelText: _isReceivable ? 'Dari (anggota/cabang)' : 'Kepada',
              controller: _party,
            ),
            const SizedBox(height: 12),
            AppTextField(
              hintText: 'mis. Iuran ERS',
              labelText: 'Kategori (opsional)',
              controller: _category,
            ),
            const SizedBox(height: 12),
            AccountPickerField(
              label: 'Akun ${_isReceivable ? 'Piutang' : 'Hutang'}',
              selected: _account,
              onTap: () async {
                final a = await pickAccount(context,
                    accounts: accounts,
                    types: _isReceivable ? ['asset'] : ['liability']);
                if (a != null) setState(() => _account = a);
              },
            ),
            const SizedBox(height: 12),
            AccountPickerField(
              label:
                  'Akun Lawan (${_isReceivable ? 'Pendapatan' : 'Beban'}) — opsional',
              selected: _counter,
              hint: 'Pilih agar otomatis dijurnal',
              onTap: () async {
                final a = await pickAccount(context,
                    accounts: accounts,
                    types: _isReceivable ? ['revenue'] : ['expense', 'asset']);
                if (a != null) setState(() => _counter = a);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    hintText: 'Nominal',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(
                        () => _amount = v.replaceAll(RegExp(r'[^0-9.]'), '')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2015),
                        lastDate: DateTime(2100),
                      );
                      if (p != null) setState(() => _date = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(orgFormatDate(_dateStr),
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Simpan',
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettleSheet extends ConsumerStatefulWidget {
  const _SettleSheet({required this.orgId, required this.item});

  final String orgId;
  final ReceivablePayableData item;

  @override
  ConsumerState<_SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends ConsumerState<_SettleSheet> {
  late String _amount = widget.item.outstandingAmount.toStringAsFixed(0);
  OrgAccount? _cash;
  final DateTime _date = DateTime.now();
  bool _saving = false;

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_cash == null) return _toast('Pilih akun kas');
    if ((double.tryParse(_amount) ?? 0) <= 0) return _toast('Nominal harus > 0');
    setState(() => _saving = true);
    try {
      await ref
          .read(orgDataSourceProvider)
          .settleReceivablePayable(widget.orgId, widget.item.id, {
        'amount': double.parse(_amount),
        'cash_account_id': _cash!.id,
        'date': _dateStr,
      });
      ref.invalidate(orgReceivablesPayablesProvider(
          (orgId: widget.orgId, type: widget.item.type)));
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('Pelunasan dicatat');
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final accounts =
        ref.watch(orgAccountsProvider(widget.orgId)).valueOrNull ?? const [];

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Catat Pelunasan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.partyName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text('Sisa: ${formatOrgRupiah(widget.item.outstandingAmount)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            hintText: 'Jumlah',
            labelText: 'Jumlah Pelunasan',
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                setState(() => _amount = v.replaceAll(RegExp(r'[^0-9.]'), '')),
          ),
          const SizedBox(height: 12),
          AccountPickerField(
            label: 'Akun Kas',
            selected: _cash,
            onTap: () async {
              final a = await pickAccount(context,
                  accounts: accounts, types: ['asset']);
              if (a != null) setState(() => _cash = a);
            },
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Catat',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
