import 'dart:async';

import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/auth/auth_state.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/utils/logger.dart';
import 'package:confindant/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  final Set<String> _pushedNotificationIds = <String>{};
  Timer? _timer;
  bool _polling = false;
  bool _permissionRequested = false;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupNotifications());
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _pollNotifications());
    WidgetsBinding.instance.addPostFrameCallback((_) => _pollNotifications());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: widget.navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        current: _itemFromIndex(widget.navigationShell.currentIndex),
        onItemSelected: (item) => _onTapNav(item, widget.navigationShell),
        onScanTap: () => context.push(RoutePaths.scan),
      ),
    );
  }

  Future<void> _pollNotifications() async {
    if (!mounted || _polling) return;
    final auth = ref.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated) return;

    final pushEnabled = ref.read(profileSettingsProvider).notificationSettings.pushEnabled;
    if (!pushEnabled) return;
    if (!_permissionGranted) {
      _permissionGranted =
          await ref.read(appNotificationServiceProvider).requestPermission();
      if (!_permissionGranted) return;
    }

    _polling = true;
    try {
      final service = ref.read(backendApiServiceProvider);
      final localNotif = ref.read(appNotificationServiceProvider);
      final notifications = await service.notifications(page: 1, perPage: 10);

      for (final item in notifications) {
        final id = item['id']?.toString() ?? item['_id']?.toString() ?? '';
        if (id.isEmpty || _pushedNotificationIds.contains(id)) {
          continue;
        }
        final read = item['read'] == true;
        if (read) continue;

        final title = item['title']?.toString() ?? 'Confindant';
        final subtitle = item['subtitle']?.toString() ?? 'You have a new notification';
        await localNotif.show(
          id: id.hashCode & 0x7fffffff,
          title: title,
          body: subtitle,
        );
        _pushedNotificationIds.add(id);
        await service.markNotificationRead(id);
      }
    } catch (e) {
      appLog('Notification polling failed: $e');
    } finally {
      _polling = false;
    }
  }

  Future<void> _setupNotifications() async {
    try {
      final notification = ref.read(appNotificationServiceProvider);
      await notification.initialize();
      await _ensurePermissionRequested();
    } catch (e) {
      appLog('Notification setup failed: $e');
    }
  }

  Future<void> _ensurePermissionRequested() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    final granted = await ref.read(appNotificationServiceProvider).requestPermission();
    if (!mounted) return;
    _permissionGranted = granted;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.notificationsPermissionMissing)),
      );
    }
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
