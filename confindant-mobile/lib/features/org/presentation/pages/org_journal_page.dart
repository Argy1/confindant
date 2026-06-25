import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/journal_models.dart';
import 'package:confindant/features/org/models/org_models.dart';
import 'package:confindant/features/org/presentation/widgets/journal_detail_sheet.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrgJournalPage extends ConsumerStatefulWidget {
  const OrgJournalPage({super.key});

  @override
  ConsumerState<OrgJournalPage> createState() => _OrgJournalPageState();
}

class _OrgJournalPageState extends ConsumerState<OrgJournalPage> {
  String _query = '';

  bool _canWrite(WidgetRef ref, String? orgId) {
    if (orgId == null) return false;
    final orgs = ref.watch(myOrganizationsProvider).valueOrNull ?? const [];
    for (final Organization o in orgs) {
      if (o.id == orgId) return o.canWrite;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);
    final canWrite = _canWrite(ref, orgId);

    return OrgScaffold(
      title: 'Jurnal Umum',
      current: OrgNavItem.journal,
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.blue900,
              foregroundColor: Colors.white,
              onPressed: () => context.push(RoutePaths.orgJournalNew),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Catat'),
            )
          : null,
      child: orgId == null
          ? const Center(child: Text('Belum ada organisasi'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Cari uraian atau nomor jurnal...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ref.watch(orgJournalProvider(orgId)).when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => _error(
                          () => ref.invalidate(orgJournalProvider(orgId)),
                        ),
                        data: (entries) {
                          final filtered = _query.trim().isEmpty
                              ? entries
                              : entries
                                  .where((e) =>
                                      e.description
                                          .toLowerCase()
                                          .contains(_query.toLowerCase()) ||
                                      (e.entryNumber ?? '')
                                          .toLowerCase()
                                          .contains(_query.toLowerCase()))
                                  .toList();
                          if (filtered.isEmpty) return _empty();
                          return RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(orgJournalProvider(orgId));
                              await ref
                                  .read(orgJournalProvider(orgId).future);
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) => _JournalTile(
                                entry: filtered[i],
                                onTap: () => showJournalDetailSheet(
                                  context,
                                  orgId: orgId,
                                  entryId: filtered[i].id,
                                  canWrite: canWrite,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
    );
  }

  Widget _empty() {
    return ListView(
      children: const [
        SizedBox(height: 100),
        Icon(Icons.receipt_long_rounded,
            size: 44, color: AppColors.textTertiary),
        SizedBox(height: 12),
        Center(
          child: Text(
            'Belum ada jurnal',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _error(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _JournalTile extends StatelessWidget {
  const _JournalTile({required this.entry, required this.onTap});

  final JournalEntryData entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              decoration: entry.isVoid
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (entry.isVoid)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Void',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${orgFormatDate(entry.date)} · ${entry.entryNumber ?? ''}'
                      '${entry.category != null ? ' · ${entry.category}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatOrgRupiah(entry.totalAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
