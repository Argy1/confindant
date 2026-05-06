import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/app_card_container.dart';
import 'package:confindant/features/home/models/home_models.dart';
import 'package:confindant/features/home/presentation/widgets/home_section_header.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class HomeQuickActionsCard extends StatelessWidget {
  const HomeQuickActionsCard({
    super.key,
    required this.actions,
    required this.onActionTap,
    this.isVoiceListening = false,
  });

  final List<HomeQuickAction> actions;
  final ValueChanged<HomeQuickActionType> onActionTap;
  final bool isVoiceListening;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCardContainer(
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        children: [
          HomeSectionHeader(title: l10n?.homeQuickActionsTitle ?? 'Quick Actions'),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final halfWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (var index = 0; index < actions.length; index++)
                    _QuickActionTile(
                      width: actions.length.isOdd && index == actions.length - 1
                          ? constraints.maxWidth
                          : halfWidth,
                      action: actions[index],
                      isVoiceListening: isVoiceListening,
                      onTap: onActionTap,
                      labelBuilder: _actionLabel,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _actionLabel(
    BuildContext context,
    HomeQuickAction action, {
    required bool isActiveVoiceTile,
  }) {
    final l10n = AppLocalizations.of(context);
    switch (action.type) {
      case HomeQuickActionType.scan:
        return 'Scan';
      case HomeQuickActionType.addExpense:
        return l10n?.homeQuickActionAddExpense ?? 'Add Expense';
      case HomeQuickActionType.addIncome:
        return l10n?.homeQuickActionAddIncome ?? 'Add Income';
      case HomeQuickActionType.addWallet:
        return l10n?.homeQuickActionAddWallet ?? 'Add Wallet';
      case HomeQuickActionType.voiceInput:
        if (isActiveVoiceTile) {
          return l10n?.homeQuickActionVoiceListening ?? 'Listening...';
        }
        return l10n?.homeQuickActionVoiceInput ?? 'Voice Input';
    }
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.width,
    required this.action,
    required this.isVoiceListening,
    required this.onTap,
    required this.labelBuilder,
  });

  final double width;
  final HomeQuickAction action;
  final bool isVoiceListening;
  final ValueChanged<HomeQuickActionType> onTap;
  final String Function(
    BuildContext context,
    HomeQuickAction action, {
    required bool isActiveVoiceTile,
  })
  labelBuilder;

  @override
  Widget build(BuildContext context) {
    final isActiveVoiceTile =
        action.type == HomeQuickActionType.voiceInput && isVoiceListening;
    return SizedBox(
      width: width,
      child: Material(
        color: isActiveVoiceTile ? const Color(0xFFEAF2FF) : const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          key: ValueKey('home_quick_action_${action.type.name}'),
          onTap: () => onTap(action.type),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            height: isActiveVoiceTile ? 104 : 92,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ActionIcon(
                    icon: action.icon,
                    isActiveVoiceTile: isActiveVoiceTile,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labelBuilder(
                      context,
                      action,
                      isActiveVoiceTile: isActiveVoiceTile,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.12,
                    ),
                  ),
                  if (isActiveVoiceTile) ...[
                    const SizedBox(height: 4),
                    const _VoiceWaveIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.isActiveVoiceTile,
  });

  final IconData icon;
  final bool isActiveVoiceTile;

  @override
  Widget build(BuildContext context) {
    if (!isActiveVoiceTile) {
      return Icon(
        icon,
        size: 20,
        color: AppColors.accentAction,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1D4ED8).withValues(alpha: 0.16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.22),
            blurRadius: 10,
            spreadRadius: 1.2,
          ),
        ],
      ),
      child: const Icon(
        Icons.mic_rounded,
        size: 20,
        color: AppColors.accentAction,
      ),
    );
  }
}

class _VoiceWaveIndicator extends StatefulWidget {
  const _VoiceWaveIndicator();

  @override
  State<_VoiceWaveIndicator> createState() => _VoiceWaveIndicatorState();
}

class _VoiceWaveIndicatorState extends State<_VoiceWaveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      width: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _WaveBar(
            controller: _controller,
            interval: const Interval(0.0, 0.7, curve: Curves.easeInOut),
          ),
          _WaveBar(
            controller: _controller,
            interval: const Interval(0.2, 0.9, curve: Curves.easeInOut),
          ),
          _WaveBar(
            controller: _controller,
            interval: const Interval(0.35, 1.0, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar({
    required this.controller,
    required this.interval,
  });

  final AnimationController controller;
  final Interval interval;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = interval.transform(controller.value);
        final height = 4 + (6 * t);
        return Container(
          width: 4,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.accentAction.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      },
    );
  }
}
