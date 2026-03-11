import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        current: _itemFromIndex(navigationShell.currentIndex),
        onItemSelected: (item) => _onTapNav(item, navigationShell),
        onScanTap: () => context.push(RoutePaths.scan),
      ),
    );
  }

  void _onTapNav(AppNavItem item, StatefulNavigationShell shell) {
    switch (item) {
      case AppNavItem.home:
        shell.goBranch(0);
        return;
      case AppNavItem.analytics:
        shell.goBranch(1);
        return;
      case AppNavItem.wallet:
        shell.goBranch(2);
        return;
      case AppNavItem.profile:
        shell.goBranch(3);
        return;
      case AppNavItem.scan:
        return;
    }
  }

  AppNavItem _itemFromIndex(int index) {
    switch (index) {
      case 0:
        return AppNavItem.home;
      case 1:
        return AppNavItem.analytics;
      case 2:
        return AppNavItem.wallet;
      case 3:
        return AppNavItem.profile;
      default:
        return AppNavItem.home;
    }
  }
}
