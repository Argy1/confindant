import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/presentation/widgets/workspace_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav destinations available in organization mode.
enum OrgNavItem { dashboard, balanceSheet, journal, activities, more }

/// Shared scaffold for organization (accounting) pages: an app bar with the
/// workspace switcher + a dedicated org bottom navigation bar.
class OrgScaffold extends ConsumerWidget {
  const OrgScaffold({
    super.key,
    required this.title,
    required this.current,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final OrgNavItem current;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.card,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const WorkspaceSwitcherButton(),
          ],
        ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: child),
      bottomNavigationBar: _OrgBottomNav(current: current),
    );
  }
}

class _OrgBottomNav extends StatelessWidget {
  const _OrgBottomNav({required this.current});

  final OrgNavItem current;

  void _go(BuildContext context, OrgNavItem item) {
    switch (item) {
      case OrgNavItem.dashboard:
        context.go(RoutePaths.orgDashboard);
      case OrgNavItem.balanceSheet:
        context.go(RoutePaths.orgBalanceSheet);
      case OrgNavItem.journal:
        context.go(RoutePaths.orgJournal);
      case OrgNavItem.activities:
        context.go(RoutePaths.orgActivities);
      case OrgNavItem.more:
        _showMoreSheet(context);
    }
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Widget tile(IconData icon, String label, String route) {
          return ListTile(
            leading: Icon(icon, color: AppColors.blue900),
            title: Text(label),
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.go(route);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 8),
              tile(Icons.menu_book_rounded, 'Buku Besar', RoutePaths.orgLedger),
              tile(Icons.account_tree_rounded, 'Bagan Akun', RoutePaths.orgAccounts),
              tile(Icons.balance_rounded, 'Neraca Saldo', RoutePaths.orgTrialBalance),
              tile(Icons.business_rounded, 'Aktiva Tetap', RoutePaths.orgFixedAssets),
              tile(Icons.handshake_rounded, 'Piutang & Hutang',
                  RoutePaths.orgReceivablesPayables),
              tile(Icons.savings_rounded, 'Dana Titipan',
                  RoutePaths.orgRestrictedFunds),
              tile(Icons.upload_file_rounded, 'Import Excel', RoutePaths.orgImport),
              const Divider(height: 1),
              tile(Icons.auto_awesome_rounded, 'AI Konsultan', RoutePaths.orgAiChat),
              tile(Icons.camera_alt_rounded, 'Scan Struk', RoutePaths.orgScan),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (_NavData(OrgNavItem.dashboard, Icons.dashboard_rounded, 'Dashboard')),
      (_NavData(OrgNavItem.balanceSheet, Icons.balance_rounded, 'Neraca')),
      (_NavData(OrgNavItem.journal, Icons.receipt_long_rounded, 'Jurnal')),
      (_NavData(OrgNavItem.activities, Icons.bar_chart_rounded, 'Aktivitas')),
      (_NavData(OrgNavItem.more, Icons.more_horiz_rounded, 'Lainnya')),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((it) {
              final selected = it.item == current;
              return Expanded(
                child: InkWell(
                  onTap: () => _go(context, it.item),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        it.icon,
                        size: 22,
                        color: selected
                            ? AppColors.blue900
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        it.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? AppColors.blue900
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavData {
  const _NavData(this.item, this.icon, this.label);
  final OrgNavItem item;
  final IconData icon;
  final String label;
}
