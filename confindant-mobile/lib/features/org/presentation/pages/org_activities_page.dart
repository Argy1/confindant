import 'dart:typed_data';

import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:file_saver/file_saver.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/presentation/widgets/ledger_sheet.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:confindant/features/org/presentation/widgets/org_report_widgets.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrgActivitiesPage extends ConsumerStatefulWidget {
  const OrgActivitiesPage({super.key});

  @override
  ConsumerState<OrgActivitiesPage> createState() => _OrgActivitiesPageState();
}

class _OrgActivitiesPageState extends ConsumerState<OrgActivitiesPage> {
  int _year = DateTime.now().year;
  bool _downloading = false;

  Future<void> _downloadPdf(String orgId) async {
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(backendApiServiceProvider)
          .orgDownloadReportPdf(orgId, 'activities', params: {'year': _year});
      await FileSaver.instance.saveFile(
        name: 'laporan-aktivitas-$_year',
        bytes: Uint8List.fromList(bytes),
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF berhasil disimpan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal unduh PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

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
    if (orgId != null) {
      ref.watch(orgAccountCodeToIdProvider(orgId));
    }

    return OrgScaffold(
      title: 'Laporan Aktivitas',
      current: OrgNavItem.activities,
      actions: orgId == null
          ? null
          : [
              IconButton(
                icon: _downloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.blue900,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded),
                tooltip: 'Unduh PDF',
                onPressed: _downloading ? null : () => _downloadPdf(orgId),
              ),
            ],
      child: orgId == null
          ? const Center(child: Text('Belum ada organisasi'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Periode $_year',
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
                    .watch(orgActivitiesProvider(OrgReportArgs(orgId, _year)))
                    .when(
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => _ActError(
                        onRetry: () => ref.invalidate(
                          orgActivitiesProvider(OrgReportArgs(orgId, _year)),
                        ),
                      ),
                      data: (data) => _ActivitiesBody(
                        data: data,
                        onAccountTap: (c, n) => _openLedger(orgId, c, n),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _ActivitiesBody extends StatelessWidget {
  const _ActivitiesBody({required this.data, required this.onAccountTap});

  final ActivitiesData data;
  final void Function(String code, String name) onAccountTap;

  @override
  Widget build(BuildContext context) {
    final positive = data.changeInNetAssets >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrgReportSectionCard(
          title: 'Penerimaan / Pendapatan',
          section: data.revenue,
          total: data.totalRevenue,
          totalLabel: 'Total Penerimaan',
          accent: const Color(0xFF047857),
          onAccountTap: onAccountTap,
        ),
        const SizedBox(height: 14),
        OrgReportSectionCard(
          title: 'Beban',
          section: data.expense,
          total: data.totalExpense,
          totalLabel: 'Total Beban',
          accent: const Color(0xFFB91C1C),
          onAccountTap: onAccountTap,
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: positive ? AppColors.blue900 : const Color(0xFFB91C1C),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'KENAIKAN (PENURUNAN) ASET BERSIH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                formatOrgRupiah(data.changeInNetAssets),
                style: const TextStyle(
                  fontSize: 16,
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

class _ActError extends StatelessWidget {
  const _ActError({required this.onRetry});

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
