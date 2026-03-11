import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/app_card_container.dart';
import 'package:confindant/features/home/models/home_models.dart';
import 'package:confindant/features/home/presentation/widgets/home_section_header.dart';
import 'package:flutter/material.dart';

class HomeQuickActionsCard extends StatelessWidget {
  const HomeQuickActionsCard({
    super.key,
    required this.actions,
    required this.onActionTap,
  });

  final List<HomeQuickAction> actions;
  final ValueChanged<HomeQuickActionType> onActionTap;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Column(
        children: [
          const HomeSectionHeader(title: 'Quick Actions'),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            itemCount: actions.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 8,
              mainAxisExtent: 60,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return Material(
                color: const Color(0xFFF4F8FF),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  key: ValueKey('home_quick_action_${action.type.name}'),
                  onTap: () => onActionTap(action.type),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        action.icon,
                        size: 19,
                        color: AppColors.accentAction,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          action.label,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
