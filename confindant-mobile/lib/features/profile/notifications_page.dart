import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/core/ai/ai_settings_controller.dart';
import 'package:confindant/core/constants/app_providers.dart';
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
    final aiSettings = ref.watch(aiSettingsProvider);
    final aiVm = ref.read(aiSettingsProvider.notifier);

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
                SettingsToggleTile(
                  label: 'AI Auto Categorization',
                  value: aiSettings.autoCategorizationEnabled,
                  onChanged: (value) => aiVm.setAutoCategorizationEnabled(value),
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
          ProfileSettingsCard(
            title: 'Notification Test',
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final granted = await ref
                          .read(appNotificationServiceProvider)
                          .requestPermission();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            granted
                                ? 'Izin notifikasi diberikan.'
                                : 'Izin notifikasi ditolak. Aktifkan dari Settings HP.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Minta Izin'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(appNotificationServiceProvider)
                          .show(
                            id: DateTime.now().millisecondsSinceEpoch % 100000,
                            title: 'Confindant',
                            body: 'Notifikasi test berhasil masuk ke perangkat.',
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifikasi test telah dikirim.'),
                        ),
                      );
                    },
                    child: const Text('Kirim Test'),
                  ),
                ),
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
