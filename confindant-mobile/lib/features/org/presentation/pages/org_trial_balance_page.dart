import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:confindant/features/org/presentation/widgets/org_report_widgets.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrgTrialBalancePage extends ConsumerStatefulWidget {
  const OrgTrialBalancePage({super.key});

  @override
  ConsumerState<OrgTrialBalancePage> createState() =>
      _OrgTrialBalancePageState();
}

class _OrgTrialBalancePageState extends ConsumerState<OrgTrialBalancePage> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);

    return OrgScaffold(
      title: 'Neraca Saldo',
      current: OrgNavItem.more,
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
                    .watch(orgTrialBalanceProvider(OrgReportArgs(orgId, _year)))
                    .when(
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: OutlinedButton(
                            onPressed: () => ref.invalidate(
                              orgTrialBalanceProvider(
                                OrgReportArgs(orgId, _year),
                              ),
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ),
                      ),
                      data: (data) => _TrialBalanceBody(data: data),
                    ),
              ],
            ),
    );
  }
}

class _TrialBalanceBody extends StatelessWidget {
  const _TrialBalanceBody({required this.data});

  final TrialBalanceData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrgStatusBanner(
          ok: data.isBalanced,
          okText: 'Seimbang — total debit = total kredit.',
          warnText: 'Tidak seimbang — periksa jurnal.',
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: const Color(0xFFF1F5F9),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Akun',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Debit',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Kredit',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...data.rows.map(
                (r) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              r.code,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontFamily: 'monospace',
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          r.debit > 0 ? formatOrgRupiah(r.debit) : '-',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          r.credit > 0 ? formatOrgRupiah(r.credit) : '-',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1.5),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 5,
                      child: Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        formatOrgRupiah(data.totalDebit),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        formatOrgRupiah(data.totalCredit),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
