import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/org_models.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:confindant/features/org/presentation/widgets/org_report_widgets.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrgDashboardPage extends ConsumerStatefulWidget {
  const OrgDashboardPage({super.key});

  @override
  ConsumerState<OrgDashboardPage> createState() => _OrgDashboardPageState();
}

class _OrgDashboardPageState extends ConsumerState<OrgDashboardPage> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);
    final orgs = ref.watch(myOrganizationsProvider).valueOrNull ?? const [];
    final orgName = orgs
        .where((o) => o.id == orgId)
        .map((o) => o.name)
        .firstOrNull;

    return OrgScaffold(
      title: 'Dashboard',
      current: OrgNavItem.dashboard,
      child: orgId == null
          ? const _NoOrg()
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(orgDashboardProvider(OrgReportArgs(orgId, _year)));
                await ref.read(
                  orgDashboardProvider(OrgReportArgs(orgId, _year)).future,
                );
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orgName ?? 'Organisasi',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
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
                      .watch(orgDashboardProvider(OrgReportArgs(orgId, _year)))
                      .when(
                        loading: () => const _DashboardLoading(),
                        error: (e, _) => _DashboardError(
                          onRetry: () => ref.invalidate(
                            orgDashboardProvider(OrgReportArgs(orgId, _year)),
                          ),
                        ),
                        data: (data) => _DashboardBody(data: data),
                      ),
                ],
              ),
            ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final OrgDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary cards (2x2)
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Aset',
                value: data.totalAssets,
                color: AppColors.blue900,
                icon: Icons.account_balance_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Kas & Setara',
                value: data.cash,
                color: const Color(0xFF059669),
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Aset Bersih',
                value: data.totalNetAssets,
                color: const Color(0xFF7C3AED),
                icon: Icons.savings_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Surplus ${data.year}',
                value: data.changeInNetAssets,
                color: const Color(0xFFD97706),
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Revenue vs expense
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _MoneyRow(
                label: 'Total Pemasukan',
                value: data.totalRevenue,
                color: const Color(0xFF047857),
                icon: Icons.arrow_downward_rounded,
              ),
              const SizedBox(height: 12),
              _MoneyRow(
                label: 'Total Beban',
                value: data.totalExpense,
                color: const Color(0xFFB91C1C),
                icon: Icons.arrow_upward_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _TopAccountsCard(
          title: 'Beban Terbesar',
          accounts: data.topExpense,
          barColor: const Color(0xFFEF4444),
        ),
        const SizedBox(height: 14),
        _TopAccountsCard(
          title: 'Pemasukan Terbesar',
          accounts: data.topRevenue,
          barColor: const Color(0xFF10B981),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 2),
          Text(
            formatOrgRupiahCompact(value),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Text(
          formatOrgRupiah(value),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TopAccountsCard extends StatelessWidget {
  const _TopAccountsCard({
    required this.title,
    required this.accounts,
    required this.barColor,
  });

  final String title;
  final List<OrgAccountAmount> accounts;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final max = accounts.isEmpty
        ? 1.0
        : accounts.map((a) => a.amount).reduce((a, b) => a > b ? a : b);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada data',
                style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              ),
            )
          else
            ...accounts.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatOrgRupiah(a.amount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: max > 0 ? a.amount / max : 0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEFF1F5),
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

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
              'Gagal memuat dashboard',
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

class _NoOrg extends StatelessWidget {
  const _NoOrg();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Belum ada organisasi. Hubungi admin untuk diberi akses.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
