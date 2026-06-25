import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _typeLabels = {
  'asset': 'Aset',
  'liability': 'Kewajiban',
  'net_asset': 'Aset Bersih',
  'revenue': 'Pendapatan',
  'expense': 'Beban',
};
const _typeOrder = ['asset', 'liability', 'net_asset', 'revenue', 'expense'];

class OrgAccountsPage extends ConsumerWidget {
  const OrgAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgId = ref.watch(activeOrgIdProvider);

    return OrgScaffold(
      title: 'Bagan Akun',
      current: OrgNavItem.more,
      child: orgId == null
          ? const Center(child: Text('Belum ada organisasi'))
          : ref.watch(orgAccountsProvider(orgId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: OutlinedButton(
                    onPressed: () => ref.invalidate(orgAccountsProvider(orgId)),
                    child: const Text('Coba Lagi'),
                  ),
                ),
                data: (accounts) => _body(accounts),
              ),
    );
  }

  Widget _body(List<OrgAccount> accounts) {
    final grouped = <String, List<OrgAccount>>{};
    for (final a in accounts) {
      grouped.putIfAbsent(a.type, () => []).add(a);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final type in _typeOrder)
          if (grouped[type] != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
              child: Text(
                _typeLabels[type] ?? type,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final a in grouped[type]!)
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              a.code,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontFamily: 'monospace',
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              a.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            a.normalBalance == 'debit' ? 'D' : 'K',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
