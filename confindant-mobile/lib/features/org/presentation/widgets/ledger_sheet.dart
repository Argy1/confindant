import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens a bottom sheet showing an account's general ledger for the year.
Future<void> showLedgerSheet(
  BuildContext context, {
  required String orgId,
  required String accountId,
  required String accountName,
  required int year,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _LedgerSheetBody(
      orgId: orgId,
      accountId: accountId,
      accountName: accountName,
      year: year,
    ),
  );
}

class _LedgerSheetBody extends ConsumerWidget {
  const _LedgerSheetBody({
    required this.orgId,
    required this.accountId,
    required this.accountName,
    required this.year,
  });

  final String orgId;
  final String accountId;
  final String accountName;
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(
      _ledgerProvider(_LedgerArgs(orgId, accountId, year)),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded,
                      size: 18, color: AppColors.blue900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buku Besar — $accountName',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: future.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Gagal memuat buku besar.\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                data: (ledger) => _LedgerList(
                  ledger: ledger,
                  scrollController: scrollController,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LedgerList extends StatelessWidget {
  const _LedgerList({required this.ledger, required this.scrollController});

  final GeneralLedgerData ledger;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _balanceRow('Saldo Awal', ledger.openingBalance, bold: true),
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
          ...ledger.lines.map(_lineRow),
        const Divider(height: 1),
        _balanceRow('Saldo Akhir', ledger.closingBalance, bold: true),
      ],
    );
  }

  Widget _lineRow(LedgerLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${orgFormatDate(line.date)}${line.entryNumber != null ? ' · ${line.entryNumber}' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatOrgRupiah(line.balance),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (line.debit > 0)
                Text(
                  'D ${formatOrgRupiah(line.debit)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF047857),
                  ),
                ),
              if (line.credit > 0)
                Text(
                  'K ${formatOrgRupiah(line.credit)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB91C1C),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceRow(String label, double value, {bool bold = false}) {
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
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            formatOrgRupiah(value),
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

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

final _ledgerProvider =
    FutureProvider.family<GeneralLedgerData, _LedgerArgs>((ref, args) async {
      return ref.watch(orgDataSourceProvider).generalLedger(
            args.orgId,
            args.accountId,
            fromDate: '${args.year}-01-01',
            toDate: '${args.year}-12-31',
          );
    });
