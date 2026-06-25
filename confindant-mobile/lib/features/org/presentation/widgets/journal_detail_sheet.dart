import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/journal_models.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows journal entry details with a void action (for users who can write).
Future<void> showJournalDetailSheet(
  BuildContext context, {
  required String orgId,
  required String entryId,
  required bool canWrite,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _JournalDetailBody(
      orgId: orgId,
      entryId: entryId,
      canWrite: canWrite,
    ),
  );
}

class _JournalDetailBody extends ConsumerStatefulWidget {
  const _JournalDetailBody({
    required this.orgId,
    required this.entryId,
    required this.canWrite,
  });

  final String orgId;
  final String entryId;
  final bool canWrite;

  @override
  ConsumerState<_JournalDetailBody> createState() => _JournalDetailBodyState();
}

class _JournalDetailBodyState extends ConsumerState<_JournalDetailBody> {
  bool _voiding = false;

  Future<void> _void() async {
    setState(() => _voiding = true);
    try {
      await ref
          .read(orgDataSourceProvider)
          .journalVoid(widget.orgId, widget.entryId);
      ref.invalidate(orgJournalProvider(widget.orgId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jurnal dibatalkan (dibuat pembalik)')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _voiding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(
      orgJournalDetailProvider((orgId: widget.orgId, id: widget.entryId)),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
            Expanded(
              child: detail.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Gagal memuat: $e')),
                data: (entry) => _content(context, entry, scrollController),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    JournalEntryData entry,
    ScrollController controller,
  ) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${orgFormatDate(entry.date)} · ${entry.entryNumber ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            _statusBadge(entry.status),
          ],
        ),
        if (entry.reference != null && entry.reference!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No. Bukti: ${entry.reference}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        const SizedBox(height: 16),
        // Lines table
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final line in entry.lines)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.accountName,
                                style: const TextStyle(fontSize: 13)),
                            Text(
                              line.accountCode,
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
                          line.debit > 0 ? formatOrgRupiah(line.debit) : '-',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          line.credit > 0 ? formatOrgRupiah(line.credit) : '-',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                color: const Color(0xFFF8FAFC),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 5,
                      child: Text(
                        'Total',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        formatOrgRupiah(entry.totalAmount),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        formatOrgRupiah(entry.totalAmount),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.canWrite && entry.status == 'posted') ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _voiding ? null : _void,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              minimumSize: const Size.fromHeight(46),
            ),
            icon: _voiding
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.block_rounded, size: 18),
            label: Text(_voiding ? 'Membatalkan...' : 'Batalkan Jurnal'),
          ),
        ],
      ],
    );
  }

  Widget _statusBadge(String status) {
    final (label, bg, fg) = switch (status) {
      'posted' => ('Diposting', const Color(0xFFECFDF5), const Color(0xFF047857)),
      'void' => ('Dibatalkan', const Color(0xFFFEF2F2), const Color(0xFFB91C1C)),
      _ => ('Draft', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
