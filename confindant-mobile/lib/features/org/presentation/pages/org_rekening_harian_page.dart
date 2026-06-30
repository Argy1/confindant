import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/org/models/org_models.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _colorIncome = Color(0xFF059669);
const _colorExpense = Color(0xFFDC2626);
const _colorIncomeBg = Color(0xFFD1FAE5);
const _colorExpenseBg = Color(0xFFFEE2E2);

class OrgRekeningHarianPage extends ConsumerStatefulWidget {
  const OrgRekeningHarianPage({super.key});

  @override
  ConsumerState<OrgRekeningHarianPage> createState() =>
      _OrgRekeningHarianPageState();
}

class _OrgRekeningHarianPageState
    extends ConsumerState<OrgRekeningHarianPage> {
  List<Map<String, dynamic>> _rows = const [];
  Map<String, dynamic> _meta = const {};
  List<String> _incomeCategories = const [];
  List<String> _expenseCategories = const [];
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
      final api = ref.read(backendApiServiceProvider);
      final result = await api.orgRekeningHarianList(orgId);
      final cats = await api.orgRekeningHarianCategories(orgId);
      if (!mounted) return;
      final rawRows = result['rows'] as List<Map<String, dynamic>>? ?? [];
      setState(() {
        _rows = rawRows;
        _meta = result['meta'] as Map<String, dynamic>? ?? {};
        _incomeCategories = (cats['income'] as List? ?? []).cast<String>();
        _expenseCategories = (cats['expense'] as List? ?? []).cast<String>();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(BuildContext ctx, int id) async {
    final orgId = ref.read(activeOrgIdProvider);
    if (orgId == null) return;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan entri?'),
        content: const Text(
          'Entri akan di-void dan jurnal akuntansi terkait juga dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan', style: TextStyle(color: _colorExpense)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(backendApiServiceProvider).orgRekeningHarianDelete(orgId, id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membatalkan: $e')),
      );
    }
  }

  void _openAdd(BuildContext ctx) async {
    final orgId = ref.read(activeOrgIdProvider);
    if (orgId == null) return;
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEntrySheet(
        orgId: orgId,
        incomeCategories: _incomeCategories,
        expenseCategories: _expenseCategories,
        apiService: ref.read(backendApiServiceProvider),
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);
    final canWrite = _canWrite(orgId);
    final runningBalance =
        (_meta['running_balance'] as num?)?.toDouble() ?? 0.0;
    final totalIn = _rows.fold<double>(
      0,
      (s, r) => s + (r['pemasukan'] as num? ?? 0).toDouble(),
    );
    final totalOut = _rows.fold<double>(
      0,
      (s, r) => s + (r['pengeluaran'] as num? ?? 0).toDouble(),
    );

    return OrgScaffold(
      title: 'Rekening Harian',
      current: OrgNavItem.more,
      actions: canWrite
          ? [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Tambah Entri',
                onPressed: () => _openAdd(context),
              ),
            ]
          : null,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _BalanceCard(
                        runningBalance: runningBalance,
                        totalIn: totalIn,
                        totalOut: totalOut,
                      ),
                    ),
                  ),
                  if (_rows.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.account_balance_outlined,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada entri',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mulai catat transaksi harian organisasi',
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                            if (canWrite) ...[
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => _openAdd(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah Entri'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final row = _rows[i];
                            final id = (row['id'] as num?)?.toInt() ?? 0;
                            final pemasukan =
                                (row['pemasukan'] as num?)?.toDouble();
                            final pengeluaran =
                                (row['pengeluaran'] as num?)?.toDouble();
                            final saldo =
                                (row['saldo'] as num?)?.toDouble() ?? 0;
                            final isIncome = pemasukan != null;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: isIncome
                                      ? _colorIncomeBg
                                      : _colorExpenseBg,
                                  child: Icon(
                                    isIncome
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: isIncome ? _colorIncome : _colorExpense,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  row['uraian']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      orgFormatDate(row['date']?.toString()),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    if (row['kategori'] != null) ...[
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          row['kategori'].toString(),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      'Saldo: ${formatOrgRupiah(saldo)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isIncome
                                          ? '+${formatOrgRupiah(pemasukan)}'
                                          : '-${formatOrgRupiah(pengeluaran!)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isIncome ? _colorIncome : _colorExpense,
                                      ),
                                    ),
                                    if (canWrite) ...[
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () => _delete(context, id),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _rows.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.runningBalance,
    required this.totalIn,
    required this.totalOut,
  });

  final double runningBalance;
  final double totalIn;
  final double totalOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue600, AppColors.blue900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Rekening',
            style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            formatOrgRupiah(runningBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: 'Pemasukan',
                  value: formatOrgRupiah(totalIn),
                  valueColor: const Color(0xFFA7F3D0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCell(
                  label: 'Pengeluaran',
                  value: formatOrgRupiah(totalOut),
                  valueColor: const Color(0xFFFCA5A5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Add Entry Bottom Sheet ----

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet({
    required this.orgId,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.apiService,
    required this.onSaved,
  });

  final String orgId;
  final List<String> incomeCategories;
  final List<String> expenseCategories;
  final dynamic apiService;
  final VoidCallback onSaved;

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _uraianCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  String _type = 'pemasukan';
  String? _kategori;
  bool _saving = false;

  @override
  void dispose() {
    _uraianCtrl.dispose();
    _amountCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      _type == 'pemasukan' ? widget.incomeCategories : widget.expenseCategories;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final raw = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah tidak valid')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final dateStr =
          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-'
          '${_date.day.toString().padLeft(2, '0')}';
      await widget.apiService.orgRekeningHarianCreate(
        widget.orgId,
        date: dateStr,
        uraian: _uraianCtrl.text.trim(),
        pemasukan: _type == 'pemasukan' ? amount : null,
        pengeluaran: _type == 'pengeluaran' ? amount : null,
        kategori: _kategori,
        keterangan:
            _keteranganCtrl.text.trim().isEmpty ? null : _keteranganCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Tambah Entri', style: AppTextStyles.sectionTitle),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _date = picked);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(orgFormatDate(_date.toIso8601String())),
            ),
            const SizedBox(height: 12),

            // Jenis
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pemasukan', label: Text('Pemasukan')),
                ButtonSegment(value: 'pengeluaran', label: Text('Pengeluaran')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _kategori = null;
              }),
            ),
            const SizedBox(height: 12),

            // Uraian
            TextFormField(
              controller: _uraianCtrl,
              decoration: const InputDecoration(
                labelText: 'Uraian',
                hintText: 'Keterangan transaksi',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 10),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                prefixText: 'Rp ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                final n = double.tryParse(
                  v.replaceAll('.', '').replaceAll(',', '.'),
                );
                if (n == null || n <= 0) return 'Masukkan angka yang valid';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Kategori
            DropdownButtonFormField<String>(
              key: ValueKey(_type),
              initialValue: _kategori,
              decoration: const InputDecoration(labelText: 'Kategori (opsional)'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('— Tanpa kategori —'),
                ),
                ..._categories.map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _kategori = v),
            ),
            const SizedBox(height: 10),

            // Keterangan
            TextFormField(
              controller: _keteranganCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan (opsional)',
                hintText: 'Referensi / catatan',
              ),
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
