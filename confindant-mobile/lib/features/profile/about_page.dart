import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:confindant/features/profile/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final about = ref.watch(profileSettingsProvider).aboutInfo;
    return ProfileDetailScaffold(
      title: 'About Confindant',
      subtitle: 'App info and legal references',
      child: Column(
        children: [
          ProfileSettingsCard(
            title: 'App Identity',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFF0E6BA8),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${about.appName} v${about.version}',
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(about.description, style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Build: ${about.build}',
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileSettingsCard(
            title: 'Legal & Policy',
            child: Column(
              children: [
                SettingsActionTile(
                  label: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Open Privacy Policy (mock).'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                SettingsActionTile(
                  label: 'Terms of Service',
                  subtitle: 'Usage terms and conditions',
                  icon: Icons.description_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Open Terms (mock).')),
                    );
                  },
                ),
                const Divider(height: 1),
                SettingsActionTile(
                  label: 'Licenses',
                  subtitle: 'Third-party dependencies',
                  icon: Icons.gavel_rounded,
                  onTap: () {
                    showLicensePage(context: context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
