import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/presentation/widgets/account_picker.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _JournalMode { simple, manual }

enum _Direction { income, expense }

class ManualLine {
  ManualLine({this.account, this.debit = '', this.credit = ''});
  OrgAccount? account;
  String debit;
  String credit;
}

class OrgJournalFormPage extends ConsumerStatefulWidget {
  const OrgJournalFormPage({super.key});

  @override
  ConsumerState<OrgJournalFormPage> createState() => _OrgJournalFormPageState();
}

class _OrgJournalFormPageState extends ConsumerState<OrgJournalFormPage> {
  _JournalMode _mode = _JournalMode.simple;
  _Direction _direction = _Direction.expense;

  final _descController = TextEditingController();
  final _refController = TextEditingController();
  DateTime _date = DateTime.now();

  // Simple mode
  OrgAccount? _cashAccount;
  OrgAccount? _categoryAccount;
  String _amount = '';

  // Manual mode
  final List<ManualLine> _lines = [ManualLine(), ManualLine()];

  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    _refController.dispose();
    super.dispose();
  }

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  double get _totalDebit =>
      _lines.fold(0, (s, l) => s + (double.tryParse(l.debit) ?? 0));
  double get _totalCredit =>
      _lines.fold(0, (s, l) => s + (double.tryParse(l.credit) ?? 0));
  bool get _balanced =>
      (_totalDebit - _totalCredit).abs() < 0.005 && _totalDebit > 0;

  Future<void> _submit(String orgId) async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      _toast('Isi uraian transaksi');
      return;
    }

    List<Map<String, dynamic>> lines;
    if (_mode == _JournalMode.simple) {
      final amt = double.tryParse(_amount) ?? 0;
      if (_categoryAccount == null) return _toast('Pilih kategori');
      if (_cashAccount == null) return _toast('Pilih akun kas');
      if (amt <= 0) return _toast('Nominal harus lebih dari 0');
      lines = _direction == _Direction.income
          ? [
              {'account_id': _cashAccount!.id, 'debit': amt},
              {'account_id': _categoryAccount!.id, 'credit': amt},
            ]
          : [
              {'account_id': _categoryAccount!.id, 'debit': amt},
              {'account_id': _cashAccount!.id, 'credit': amt},
            ];
    } else {
      final valid = _lines
          .where((l) =>
              l.account != null &&
              ((double.tryParse(l.debit) ?? 0) > 0 ||
                  (double.tryParse(l.credit) ?? 0) > 0))
          .toList();
      if (valid.length < 2) return _toast('Minimal 2 baris dengan akun & nilai');
      if (!_balanced) return _toast('Total debit harus sama dengan total kredit');
      lines = valid
          .map((l) => {
                'account_id': l.account!.id,
                'debit': double.tryParse(l.debit) ?? 0,
                'credit': double.tryParse(l.credit) ?? 0,
              })
          .toList();
    }

    setState(() => _submitting = true);
    try {
      await ref.read(orgDataSourceProvider).journalCreate(orgId, {
        'date': _dateStr,
        'description': desc,
        'reference': _refController.text.trim().isEmpty
            ? null
            : _refController.text.trim(),
        'lines': lines,
      });
      ref.invalidate(orgJournalProvider(orgId));
      ref.invalidate(orgDashboardProvider(OrgReportArgs(orgId, _date.year)));
      if (!mounted) return;
      _toast('Jurnal berhasil disimpan');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);
    final accounts =
        orgId == null ? const <OrgAccount>[] : (ref.watch(orgAccountsProvider(orgId)).valueOrNull ?? const []);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.card,
        elevation: 0,
        title: const Text(
          'Catat Transaksi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: orgId == null
          ? const Center(child: Text('Belum ada organisasi'))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _modeToggle(),
                        const SizedBox(height: 16),
                        _commonFields(context),
                        const SizedBox(height: 16),
                        if (_mode == _JournalMode.simple)
                          _simpleFields(context, accounts)
                        else
                          _manualFields(context, accounts),
                      ],
                    ),
                  ),
                  _bottomBar(orgId),
                ],
              ),
            ),
    );
  }

  Widget _modeToggle() {
    Widget btn(String label, IconData icon, _JournalMode mode) {
      final active = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mode = mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 15,
                    color: active ? AppColors.blue900 : AppColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.blue900 : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          btn('Sederhana', Icons.auto_fix_high_rounded, _JournalMode.simple),
          btn('Jurnal Manual', Icons.tune_rounded, _JournalMode.manual),
        ],
      ),
    );
  }

  Widget _commonFields(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Text(orgFormatDate(_dateStr),
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextField(
                hintText: 'No. Bukti',
                controller: _refController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          hintText: 'mis. Iuran ERS dr. Aria',
          labelText: 'Uraian',
          controller: _descController,
        ),
      ],
    );
  }

  Widget _simpleFields(BuildContext context, List<OrgAccount> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _dirButton('Terima Uang', Icons.south_west_rounded,
                  _Direction.income, const Color(0xFF10B981)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dirButton('Keluar Uang', Icons.north_east_rounded,
                  _Direction.expense, const Color(0xFFEF4444)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AccountPickerField(
          label: _direction == _Direction.income
              ? 'Sumber / Kategori Pemasukan'
              : 'Kategori Beban',
          selected: _categoryAccount,
          onTap: () async {
            final acc = await pickAccount(
              context,
              accounts: accounts,
              types: _direction == _Direction.income
                  ? ['revenue']
                  : ['expense'],
            );
            if (acc != null) setState(() => _categoryAccount = acc);
          },
        ),
        const SizedBox(height: 12),
        AccountPickerField(
          label: _direction == _Direction.income ? 'Masuk ke' : 'Dibayar dari',
          selected: _cashAccount,
          onTap: () async {
            final acc = await pickAccount(context,
                accounts: accounts, types: ['asset'], title: 'Pilih Akun Kas');
            if (acc != null) setState(() => _cashAccount = acc);
          },
        ),
        const SizedBox(height: 12),
        AppTextField(
          hintText: '0',
          labelText: 'Nominal',
          keyboardType: TextInputType.number,
          onChanged: (v) =>
              setState(() => _amount = v.replaceAll(RegExp(r'[^0-9.]'), '')),
        ),
        if ((double.tryParse(_amount) ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              formatOrgRupiah(double.parse(_amount)),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textTertiary),
            ),
          ),
      ],
    );
  }

  Widget _dirButton(
      String label, IconData icon, _Direction dir, Color color) {
    final active = _direction == dir;
    return GestureDetector(
      onTap: () => setState(() {
        _direction = dir;
        _categoryAccount = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? color : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _manualFields(BuildContext context, List<OrgAccount> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._lines.asMap().entries.map((entry) {
          final i = entry.key;
          final line = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final acc =
                              await pickAccount(context, accounts: accounts);
                          if (acc != null) {
                            setState(() => line.account = acc);
                          }
                        },
                        child: Text(
                          line.account?.name ?? 'Pilih akun',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: line.account == null
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (_lines.length > 2)
                      GestureDetector(
                        onTap: () => setState(() => _lines.removeAt(i)),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textTertiary),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Debit',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) =>
                            setState(() {
                          line.debit = v;
                          line.credit = '';
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Kredit',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() {
                          line.credit = v;
                          line.debit = '';
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => setState(() => _lines.add(ManualLine())),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Tambah Baris'),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _balanced ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  _balanced ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _balanced ? 'Seimbang ✓' : 'Belum seimbang',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _balanced
                        ? const Color(0xFF065F46)
                        : const Color(0xFF92400E),
                  ),
                ),
              ),
              Text(
                'D ${formatOrgRupiah(_totalDebit)} · K ${formatOrgRupiah(_totalCredit)}',
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(String orgId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: AppPrimaryButton(
        label: 'Simpan Jurnal',
        icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
        isLoading: _submitting,
        onPressed: _submitting ? null : () => _submit(orgId),
      ),
    );
  }
}
