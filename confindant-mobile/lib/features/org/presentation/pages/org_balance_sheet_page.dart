import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/presentation/widgets/ledger_sheet.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:confindant/features/org/presentation/widgets/org_report_widgets.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrgBalanceSheetPage extends ConsumerStatefulWidget {
  const OrgBalanceSheetPage({super.key});

  @override
  ConsumerState<OrgBalanceSheetPage> createState() =>
      _OrgBalanceSheetPageState();
}

class _OrgBalanceSheetPageState extends ConsumerState<OrgBalanceSheetPage> {
  int _year = DateTime.now().year;

  void _openLedger(String orgId, String code, String name) {
    final map =
        ref.read(orgAccountCodeToIdProvider(orgId)).valueOrNull ?? const {};
    final id = map[code];
    if (id == null) return;
    showLedgerSheet(
      context,
      orgId: orgId,
      accountId: id,
      accountName: name,
      year: _year,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);
    // Warm the code->id map for drill-down.
    if (orgId != null) {
      ref.watch(orgAccountCodeToIdProvider(orgId));
    }

    return OrgScaffold(
      title: 'Neraca',
      current: OrgNavItem.balanceSheet,
      child: orgId == null
          ? const Center(child: Text('Belum ada organisasi'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Per 31 Des $_year',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    OrgYearSelector(
                      year: _year,
                      onChanged: (y) => setState(() => _year = y),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ref
                    .watch(orgBalanceSheetProvider(OrgReportArgs(orgId, _year)))
                    .when(
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => _ReportError(
                        onRetry: () => ref.invalidate(
                          orgBalanceSheetProvider(OrgReportArgs(orgId, _year)),
                        ),
                      ),
                      data: (data) => _BalanceSheetBody(
                        data: data,
                        onAccountTap: (code, name) =>
                            _openLedger(orgId, code, name),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _BalanceSheetBody extends StatelessWidget {
  const _BalanceSheetBody({required this.data, required this.onAccountTap});

  final BalanceSheetData data;
  final void Function(String code, String name) onAccountTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrgStatusBanner(
          ok: data.isBalanced,
          okText: 'Neraca seimbang.',
          warnText:
              'Neraca tidak seimbang. Selisih ${formatOrgRupiah(data.difference)}.',
        ),
        const SizedBox(height: 14),
        OrgReportSectionCard(
          title: 'Aset',
          section: data.assets,
          total: data.totalAssets,
          totalLabel: 'Total Aset',
          accent: AppColors.blue900,
          onAccountTap: onAccountTap,
        ),
        const SizedBox(height: 14),
        OrgReportSectionCard(
          title: 'Kewajiban',
          section: data.liabilities,
          total: data.totalLiabilities,
          totalLabel: 'Total Kewajiban',
          accent: const Color(0xFFB91C1C),
          onAccountTap: onAccountTap,
        ),
        const SizedBox(height: 14),
        _NetAssetsCard(data: data),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.blue900,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL KEWAJIBAN & ASET BERSIH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                formatOrgRupiah(data.totalLiabilitiesAndNetAssets),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NetAssetsCard extends StatelessWidget {
  const _NetAssetsCard({required this.data});

  final BalanceSheetData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: const Text(
              'ASET BERSIH',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          ...data.netAssetAccounts.map(
            (a) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      a.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    formatOrgRupiah(a.amount),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kenaikan (Penurunan) Aset Bersih',
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                Text(
                  formatOrgRupiah(data.changeInNetAssets),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL ASET BERSIH',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue900,
                    ),
                  ),
                ),
                Text(
                  formatOrgRupiah(data.totalNetAssets),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat laporan',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
