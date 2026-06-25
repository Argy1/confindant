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

const _fundTypes = [
  ('titipan_cabang', 'Dana Titipan Cabang'),
  ('titipan_kegiatan', 'Dana Titipan Kegiatan Ilmiah'),
  ('shu', 'SHU'),
];

String _fundTypeLabel(String? t) {
  for (final ft in _fundTypes) {
    if (ft.$1 == t) return ft.$2;
  }
  return t ?? '—';
}

class OrgRestrictedFundsPage extends ConsumerWidget {
  const OrgRestrictedFundsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgId = ref.watch(activeOrgIdProvider);
    final canWrite = ref.watch(orgCanWriteProvider(orgId));

    return OrgScaffold(
      title: 'Dana Titipan',
      current: OrgNavItem.more,
      floatingActionButton: canWrite && orgId != null
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.blue900,
              foregroundColor: Colors.white,
              onPressed: () => _showAddSheet(context, orgId),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Dana'),
            )
          : null,
      child: orgId == null
          ? const Center(child: Text('Belum ada organisasi'))
          : ref.watch(orgRestrictedFundsProvider(orgId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(orgRestrictedFundsProvider(orgId)),
                    child: const Text('Coba Lagi'),
                  ),
                ),
                data: (funds) => _Body(
                  orgId: orgId,
                  funds: funds,
                  canWrite: canWrite,
                ),
              ),
    );
  }

  static void _showAddSheet(BuildContext context, String orgId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddFundSheet(orgId: orgId),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.orgId,
    required this.funds,
    required this.canWrite,
  });

  final String orgId;
  final List<RestrictedFundData> funds;
  final bool canWrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = funds.fold<double>(0, (s, f) => s + f.balance);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(orgRestrictedFundsProvider(orgId));
        await ref.read(orgRestrictedFundsProvider(orgId).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
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
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.savings_rounded,
                      size: 18, color: Color(0xFF7C3AED)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Saldo Dana Titipan',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary),
                      ),
                      Text(
                        formatOrgRupiah(total),
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
          if (funds.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  'Belum ada dana titipan',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textTertiary),
                ),
              ),
            )
          else
            ...funds.map((f) => _fundCard(context, ref, f)),
        ],
      ),
    );
  }

  Widget _fundCard(BuildContext context, WidgetRef ref, RestrictedFundData f) {
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
          Text(
            f.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            _fundTypeLabel(f.fundType),
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            formatOrgRupiah(f.balance),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (canWrite) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showMoveSheet(context, f),
                child: const Text('Catat Pergerakan'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMoveSheet(BuildContext context, RestrictedFundData fund) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MoveSheet(orgId: orgId, fund: fund),
    );
  }
}

class _AddFundSheet extends ConsumerStatefulWidget {
  const _AddFundSheet({required this.orgId});

  final String orgId;

  @override
  ConsumerState<_AddFundSheet> createState() => _AddFundSheetState();
}

class _AddFundSheetState extends ConsumerState<_AddFundSheet> {
  final _name = TextEditingController();
  String _fundType = 'titipan_cabang';
  OrgAccount? _account;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return _toast('Isi nama dana');
    if (_account == null) return _toast('Pilih akun kewajiban');
    setState(() => _saving = true);
    try {
      await ref.read(orgDataSourceProvider).createRestrictedFund(widget.orgId, {
        'name': _name.text.trim(),
        'fund_type': _fundType,
        'account_id': _account!.id,
      });
      ref.invalidate(orgRestrictedFundsProvider(widget.orgId));
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('Dana titipan dibuat');
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
          const Text('Tambah Dana Titipan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          AppTextField(
            hintText: 'mis. Dana Titipan Cabang Jakarta',
            labelText: 'Nama Dana',
            controller: _name,
          ),
          const SizedBox(height: 12),
          const Text('Jenis',
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
                value: _fundType,
                isExpanded: true,
                items: _fundTypes
                    .map((t) =>
                        DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _fundType = v ?? _fundType),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AccountPickerField(
            label: 'Akun Kewajiban',
            selected: _account,
            onTap: () async {
              final a = await pickAccount(context,
                  accounts: accounts, types: ['liability']);
              if (a != null) setState(() => _account = a);
            },
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

class _MoveSheet extends ConsumerStatefulWidget {
  const _MoveSheet({required this.orgId, required this.fund});

  final String orgId;
  final RestrictedFundData fund;

  @override
  ConsumerState<_MoveSheet> createState() => _MoveSheetState();
}

class _MoveSheetState extends ConsumerState<_MoveSheet> {
  String _direction = 'in';
  String _amount = '';
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
          .moveRestrictedFund(widget.orgId, widget.fund.id, {
        'direction': _direction,
        'amount': double.parse(_amount),
        'cash_account_id': _cash!.id,
        'date': _dateStr,
      });
      ref.invalidate(orgRestrictedFundsProvider(widget.orgId));
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('Pergerakan dicatat');
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

    Widget dirBtn(String value, String label, IconData icon, Color color) {
      final active = _direction == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _direction = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active ? color.withValues(alpha: 0.1) : AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? color : AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

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
          const Text('Pergerakan Dana',
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
                Text(widget.fund.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text('Saldo: ${formatOrgRupiah(widget.fund.balance)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              dirBtn('in', 'Masuk', Icons.south_west_rounded,
                  const Color(0xFF10B981)),
              const SizedBox(width: 10),
              dirBtn('out', 'Keluar', Icons.north_east_rounded,
                  const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            hintText: 'Nominal',
            labelText: 'Nominal',
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
