import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:confindant/features/profile/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileSettingsProvider);
    final vm = ref.read(profileSettingsProvider.notifier);
    final settings = state.notificationSettings;

    return ProfileDetailScaffold(
      title: 'Notifications',
      subtitle: 'Control reminders and alerts',
      child: Column(
        children: [
          ProfileSettingsCard(
            title: 'Notification Settings',
            child: Column(
              children: [
                SettingsToggleTile(
                  label: 'Push Notifications',
                  value: settings.pushEnabled,
                  onChanged: vm.togglePush,
                ),
                SettingsToggleTile(
                  label: 'Email Notifications',
                  value: settings.emailEnabled,
                  onChanged: vm.toggleEmail,
                ),
                SettingsToggleTile(
                  label: 'Transaction Alerts',
                  value: settings.transactionAlerts,
                  onChanged: vm.toggleTransactionAlerts,
                ),
                SettingsToggleTile(
                  label: 'Budget Alerts',
                  value: settings.budgetAlerts,
                  onChanged: vm.toggleBudgetAlerts,
                ),
                SettingsToggleTile(
                  label: 'Weekly Report',
                  value: settings.weeklyReport,
                  onChanged: vm.toggleWeeklyReport,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileSettingsCard(
            title: 'Recent Notifications',
            child: Column(
              children: [
                for (var i = 0; i < state.recentNotifications.length; i++) ...[
                  SettingsActionTile(
                    label: state.recentNotifications[i].title,
                    subtitle:
                        '${state.recentNotifications[i].subtitle} • ${state.recentNotifications[i].timeLabel}',
                    icon: Icons.notifications_active_outlined,
                  ),
                  if (i != state.recentNotifications.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Perubahan pengaturan disinkronkan ke server.',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
