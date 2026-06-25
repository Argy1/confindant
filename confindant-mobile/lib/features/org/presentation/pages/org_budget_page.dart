import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/org/models/management_models.dart';
import 'package:confindant/features/org/models/org_models.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/presentation/widgets/account_picker.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:confindant/features/org/presentation/widgets/org_report_widgets.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrgBudgetPage extends ConsumerStatefulWidget {
  const OrgBudgetPage({super.key});

  @override
  ConsumerState<OrgBudgetPage> createState() => _OrgBudgetPageState();
}

class _OrgBudgetPageState extends ConsumerState<OrgBudgetPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _year = DateTime.now().year;

  // Budget tab
  List<OrgBudgetData> _budgets = const [];
  bool _loadingBudgets = true;

  // Compare tab
  BudgetCompareData? _compare;
  bool _loadingCompare = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _reload();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _canWrite(String? orgId) {
    if (orgId == null) return false;
    final orgs = ref.read(myOrganizationsProvider).valueOrNull ?? const [];
    for (final Organization o in orgs) {
      if (o.id == orgId) return o.canWrite;
    }
    return false;
  }

  Future<void> _reload() async {
    final orgId = ref.read(activeOrgIdProvider);
    if (orgId == null) return;
    if (_tabs.index == 0) {
      await _loadBudgets(orgId);
    } else {
      await _loadCompare(orgId);
    }
  }

  Future<void> _loadBudgets(String orgId) async {
    setState(() => _loadingBudgets = true);
    try {
      final raw = await ref
          .read(backendApiServiceProvider)
          .orgBudgetList(orgId, fiscalYear: _year);
      if (!mounted) return;
      setState(() => _budgets = raw.map(OrgBudgetData.fromJson).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat anggaran: $e')));
    } finally {
      if (mounted) setState(() => _loadingBudgets = false);
    }
  }

  Future<void> _loadCompare(String orgId) async {
    setState(() => _loadingCompare = true);
    try {
      final raw = await ref
          .read(backendApiServiceProvider)
          .orgBudgetCompare(orgId, fiscalYear: _year);
      if (!mounted) return;
      setState(() => _compare = BudgetCompareData.fromJson(raw));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat realisasi: $e')));
    } finally {
      if (mounted) setState(() => _loadingCompare = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);
    final canWrite = _canWrite(orgId);

    return OrgScaffold(
      title: 'Budget & Realisasi',
      current: OrgNavItem.more,
      floatingActionButton: canWrite && _tabs.index == 0
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
          : Column(
              children: [
                // Year selector + tabs
                Container(
                  color: AppColors.card,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Tahun Anggaran:',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      OrgYearSelector(
                        year: _year,
                        onChanged: (y) {
                          setState(() => _year = y);
                          _reload();
                        },
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  tabs: const [
                    Tab(text: 'Rencana Anggaran'),
                    Tab(text: 'Realisasi'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _BudgetTab(
                        items: _budgets,
                        loading: _loadingBudgets,
                        canWrite: canWrite,
                        onEdit: (item) =>
                            _openForm(context, orgId: orgId, existing: item),
                        onDelete: (item) => _delete(orgId, item),
                      ),
                      _CompareTab(
                        data: _compare,
                        loading: _loadingCompare,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    required String orgId,
    OrgBudgetData? existing,
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
      builder: (ctx) => _BudgetForm(
        accounts: accounts,
        existing: existing,
        fiscalYear: _year,
      ),
    );
    if (result == null || !mounted) return;
    try {
      if (existing == null) {
        await ref
            .read(backendApiServiceProvider)
            .orgBudgetCreate(orgId, result);
      } else {
        await ref
            .read(backendApiServiceProvider)
            .orgBudgetUpdate(orgId, existing.id, result);
      }
      await _loadBudgets(orgId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  Future<void> _delete(String orgId, OrgBudgetData item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus anggaran?'),
        content: Text('Hapus "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref
          .read(backendApiServiceProvider)
          .orgBudgetDelete(orgId, item.id);
      await _loadBudgets(orgId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }
}

// ---- Budget list tab -------------------------------------------------------

class _BudgetTab extends StatelessWidget {
  const _BudgetTab({
    required this.items,
    required this.loading,
    required this.canWrite,
    required this.onEdit,
    required this.onDelete,
  });

  final List<OrgBudgetData> items;
  final bool loading;
  final bool canWrite;
  final void Function(OrgBudgetData) onEdit;
  final void Function(OrgBudgetData) onDelete;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Belum ada rencana anggaran.',
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, i) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = items[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            title: Text(
              item.name,
              style: AppTextStyles.label
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.accountCode != null)
                  Text(
                    '${item.accountCode} · ${item.accountName ?? ''}',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                if (item.category != null)
                  Text(
                    item.category!,
                    style: AppTextStyles.caption.copyWith(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatOrgRupiahCompact(item.amountPlanned),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue900,
                  ),
                ),
                if (canWrite)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        size: 18, color: AppColors.textSecondary),
                    onSelected: (v) {
                      if (v == 'edit') onEdit(item);
                      if (v == 'delete') onDelete(item);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus',
                            style:
                                TextStyle(color: Color(0xFFB91C1C))),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---- Compare tab -----------------------------------------------------------

class _CompareTab extends StatelessWidget {
  const _CompareTab({required this.data, required this.loading});

  final BudgetCompareData? data;
  final bool loading;

  Color _barColor(double pct) {
    if (pct > 100) return const Color(0xFFEF4444);
    if (pct >= 80) return const Color(0xFFF59E0B);
    return const Color(0xFF3B82F6);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final d = data;
    if (d == null || d.items.isEmpty) {
      return Center(
        child: Text(
          'Belum ada data realisasi.',
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Anggaran',
                value: formatOrgRupiahCompact(d.totalPlanned),
                color: AppColors.blue900,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Realisasi',
                value: formatOrgRupiahCompact(d.totalActual),
                color: d.totalActual > d.totalPlanned
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Selisih',
                value: formatOrgRupiahCompact(d.totalVariance),
                color: d.totalVariance < 0
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Serapan',
                value:
                    '${d.overallPercentage.toStringAsFixed(1)}%',
                color: _barColor(d.overallPercentage),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Per-item rows
        ...d.items.map((item) {
          final pct = item.percentage.clamp(0, 150).toDouble();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${item.percentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _barColor(item.percentage),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 150,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _barColor(item.percentage)),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Anggaran: ${formatOrgRupiahCompact(item.amountPlanned)}',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                    Text(
                      'Realisasi: ${formatOrgRupiahCompact(item.amountActual)}',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

// ---- Form -----------------------------------------------------------------

class _BudgetForm extends StatefulWidget {
  const _BudgetForm({
    required this.accounts,
    required this.fiscalYear,
    this.existing,
  });

  final List<OrgAccount> accounts;
  final int fiscalYear;
  final OrgBudgetData? existing;

  @override
  State<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<_BudgetForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _notesCtrl;
  OrgAccount? _account;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl =
        TextEditingController(text: e != null ? e.amountPlanned.toStringAsFixed(0) : '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    if (e?.accountId != null) {
      _account =
          widget.accounts.where((a) => a.id == e!.accountId).firstOrNull;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _notesCtrl.dispose();
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
              isEdit ? 'Edit Anggaran' : 'Tambah Anggaran',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Anggaran'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Jumlah Dianggarkan (Rp)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _categoryCtrl,
              decoration:
                  const InputDecoration(labelText: 'Kategori (opsional)'),
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickAccount,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Akun Terkait (opsional)',
                  suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                ),
                child: _account == null
                    ? Text('Pilih akun...',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary))
                    : Text('${_account!.code} · ${_account!.name}',
                        style: AppTextStyles.caption),
              ),
            ),
            if (_account != null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _account = null),
                  child: const Text('Hapus akun'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
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
                      borderRadius: BorderRadius.circular(12)),
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

  Future<void> _pickAccount() async {
    final picked = await pickAccount(
      context,
      accounts: widget.accounts,
      title: 'Pilih Akun',
    );
    if (picked == null || !mounted) return;
    setState(() => _account = picked);
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama anggaran tidak boleh kosong.')));
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah harus lebih dari 0.')));
      return;
    }
    Navigator.of(context).pop({
      'name': name,
      'fiscal_year': widget.fiscalYear,
      'amount_planned': amount,
      'category':
          _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      'account_id': _account?.id,
      'notes':
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    });
  }
}
