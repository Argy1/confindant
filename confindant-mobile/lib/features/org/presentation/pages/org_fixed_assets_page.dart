import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/management_models.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _groups = [
  ('PERLENGKAPAN', 'Perlengkapan / Peralatan (25%)'),
  ('BANGUNAN', 'Bangunan (5%)'),
  ('TANAH', 'Tanah (tanpa penyusutan)'),
];

class OrgFixedAssetsPage extends ConsumerStatefulWidget {
  const OrgFixedAssetsPage({super.key});

  @override
  ConsumerState<OrgFixedAssetsPage> createState() => _OrgFixedAssetsPageState();
}

class _OrgFixedAssetsPageState extends ConsumerState<OrgFixedAssetsPage> {
  bool _runningDep = false;

  Future<void> _runDepreciation(String orgId) async {
    final year = DateTime.now().year;
    setState(() => _runningDep = true);
    try {
      final res =
          await ref.read(orgDataSourceProvider).runDepreciation(orgId, year);
      ref.invalidate(orgFixedAssetsProvider(orgId));
      if (!mounted) return;
      final posted = res['posted'] ?? 0;
      final amount = asDoubleSafe(res['total_amount']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Penyusutan $year: $posted aset (${formatOrgRupiah(amount)})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _runningDep = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);
    final canWrite = ref.watch(orgCanWriteProvider(orgId));

    return OrgScaffold(
      title: 'Aktiva Tetap',
      current: OrgNavItem.more,
      floatingActionButton: canWrite && orgId != null
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.blue900,
              foregroundColor: Colors.white,
              onPressed: () => _showAddSheet(orgId),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah'),
            )
          : null,
      child: orgId == null
          ? const Center(child: Text('Belum ada organisasi'))
          : ref.watch(orgFixedAssetsProvider(orgId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(orgFixedAssetsProvider(orgId)),
                    child: const Text('Coba Lagi'),
                  ),
                ),
                data: (assets) => _body(orgId, assets, canWrite),
              ),
    );
  }

  Widget _body(String orgId, List<FixedAssetData> assets, bool canWrite) {
    final totalCost = assets.fold<double>(0, (s, a) => s + a.acquisitionCost);
    final totalAccum =
        assets.fold<double>(0, (s, a) => s + a.accumulatedDepreciation);
    final totalBook = assets.fold<double>(0, (s, a) => s + a.bookValue);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(orgFixedAssetsProvider(orgId));
        await ref.read(orgFixedAssetsProvider(orgId).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          Row(
            children: [
              Expanded(child: _summaryCard('Harga Perolehan', totalCost)),
              const SizedBox(width: 8),
              Expanded(child: _summaryCard('Akm. Penyusutan', totalAccum)),
              const SizedBox(width: 8),
              Expanded(
                  child: _summaryCard('Nilai Buku', totalBook, strong: true)),
            ],
          ),
          if (canWrite) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _runningDep ? null : () => _runDepreciation(orgId),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              icon: _runningDep
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                _runningDep
                    ? 'Memproses...'
                    : 'Jalankan Penyusutan ${DateTime.now().year}',
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (assets.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Belum ada aset',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textTertiary),
                ),
              ),
            )
          else
            ...assets.map(_assetTile),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double value, {bool strong = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 4),
          Text(
            formatOrgRupiahCompact(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: strong ? AppColors.blue900 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetTile(FixedAssetData a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${a.group ?? ''} · ${orgFormatDate(a.acquisitionDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatOrgRupiah(a.bookValue),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Nilai buku',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddSheet(String orgId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddAssetSheet(orgId: orgId),
    );
  }
}

double asDoubleSafe(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

class _AddAssetSheet extends ConsumerStatefulWidget {
  const _AddAssetSheet({required this.orgId});

  final String orgId;

  @override
  ConsumerState<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends ConsumerState<_AddAssetSheet> {
  final _name = TextEditingController();
  String _group = 'PERLENGKAPAN';
  DateTime _date = DateTime.now();
  String _cost = '';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return _toast('Isi nama aset');
    if ((double.tryParse(_cost) ?? 0) <= 0) {
      return _toast('Harga perolehan harus > 0');
    }
    setState(() => _saving = true);
    try {
      await ref.read(orgDataSourceProvider).createFixedAsset(widget.orgId, {
        'name': _name.text.trim(),
        'group': _group,
        'acquisition_date': _dateStr,
        'acquisition_cost': double.parse(_cost),
      });
      ref.invalidate(orgFixedAssetsProvider(widget.orgId));
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('Aset ditambahkan');
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Tambah Aktiva Tetap',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          AppTextField(
            hintText: 'mis. Laptop Dell',
            labelText: 'Nama Aset',
            controller: _name,
          ),
          const SizedBox(height: 12),
          const Text('Kelompok',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _group,
                isExpanded: true,
                items: _groups
                    .map((g) =>
                        DropdownMenuItem(value: g.$1, child: Text(g.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _group = v ?? _group),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
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
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  hintText: 'Harga',
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      setState(() => _cost = v.replaceAll(RegExp(r'[^0-9.]'), '')),
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
    );
  }
}
