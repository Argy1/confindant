import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/presentation/widgets/account_picker.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _LedgerArgs {
  const _LedgerArgs(this.orgId, this.accountId, this.year);
  final String orgId;
  final String accountId;
  final int year;

  @override
  bool operator ==(Object other) =>
      other is _LedgerArgs &&
      other.orgId == orgId &&
      other.accountId == accountId &&
      other.year == year;

  @override
  int get hashCode => Object.hash(orgId, accountId, year);
}

final _ledgerPageProvider =
    FutureProvider.family<GeneralLedgerData, _LedgerArgs>((ref, args) async {
      return ref.watch(orgDataSourceProvider).generalLedger(
            args.orgId,
            args.accountId,
            fromDate: '${args.year}-01-01',
            toDate: '${args.year}-12-31',
          );
    });

class OrgLedgerPage extends ConsumerStatefulWidget {
  const OrgLedgerPage({super.key});

  @override
  ConsumerState<OrgLedgerPage> createState() => _OrgLedgerPageState();
}

class _OrgLedgerPageState extends ConsumerState<OrgLedgerPage> {
  OrgAccount? _account;
  final int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);
    final accounts = orgId == null
        ? const <OrgAccount>[]
        : (ref.watch(orgAccountsProvider(orgId)).valueOrNull ?? const []);

    // Default to Kas (1-1000).
    if (_account == null && accounts.isNotEmpty) {
      _account = accounts.firstWhere(
        (a) => a.code == '1-1000',
        orElse: () => accounts.first,
      );
    }

    return OrgScaffold(
      title: 'Buku Besar',
      current: OrgNavItem.more,
      child: orgId == null
          ? const Center(child: Text('Belum ada organisasi'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: AccountPickerField(
                    label: 'Akun',
                    selected: _account,
                    onTap: () async {
                      final acc =
                          await pickAccount(context, accounts: accounts);
                      if (acc != null) setState(() => _account = acc);
                    },
                  ),
                ),
                Expanded(
                  child: _account == null
                      ? const Center(child: Text('Pilih akun untuk melihat buku besar'))
                      : ref
                          .watch(_ledgerPageProvider(
                              _LedgerArgs(orgId, _account!.id, _year)))
                          .when(
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, _) => Center(child: Text('Gagal: $e')),
                            data: (ledger) => _LedgerView(ledger: ledger),
                          ),
                ),
              ],
            ),
    );
  }
}

class _LedgerView extends StatelessWidget {
  const _LedgerView({required this.ledger});

  final GeneralLedgerData ledger;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.blue900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ledger.accountName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ledger.accountCode,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Saldo Akhir',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  Text(
                    formatOrgRupiah(ledger.closingBalance),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _row('Saldo Awal', null, null, ledger.openingBalance, bold: true),
        const Divider(height: 1),
        if (ledger.lines.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Tidak ada transaksi pada periode ini',
                style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              ),
            ),
          )
        else
          ...ledger.lines.map(
            (l) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatOrgRupiah(l.balance),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            orgFormatDate(l.date),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textTertiary),
                          ),
                          const Spacer(),
                          if (l.debit > 0)
                            Text(
                              'D ${formatOrgRupiah(l.debit)}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF047857)),
                            ),
                          if (l.credit > 0)
                            Text(
                              'K ${formatOrgRupiah(l.credit)}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFFB91C1C)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        _row('Saldo Akhir', null, null, ledger.closingBalance, bold: true),
      ],
    );
  }

  Widget _row(String label, double? d, double? c, double bal, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            formatOrgRupiah(bal),
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
