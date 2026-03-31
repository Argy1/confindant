import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:confindant/features/profile/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HelpCenterPage extends ConsumerWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileSettingsProvider);
    final vm = ref.read(profileSettingsProvider.notifier);

    return ProfileDetailScaffold(
      title: 'Help Center',
      subtitle: 'Find answers and support',
      child: Column(
        children: [
          ProfileSettingsCard(
            title: 'FAQ',
            child: Column(
              children: [
                for (var i = 0; i < state.faqItems.length; i++) ...[
                  FaqExpandableCard(
                    question: state.faqItems[i].question,
                    answer: state.faqItems[i].answer,
                    expanded: state.faqItems[i].expanded,
                    onTap: () => vm.toggleFaqExpanded(i),
                  ),
                  if (i != state.faqItems.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileSettingsCard(
            title: 'Contact Support',
            child: Column(
              children: [
                SettingsActionTile(
                  label: 'Email Support',
                  subtitle: 'support@confindant.app',
                  icon: Icons.mail_outline_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Open email client (mock).'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                SettingsActionTile(
                  label: 'WhatsApp Support',
                  subtitle: '+62 811 2345 678',
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Open WhatsApp (mock).')),
                    );
                  },
                ),
                const Divider(height: 1),
                SettingsActionTile(
                  label: 'Report a Problem',
                  subtitle: 'Send bug report and screenshots',
                  icon: Icons.bug_report_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted (mock).')),
                    );
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
