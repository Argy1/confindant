import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:confindant/features/profile/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileSettingsProvider).userData;

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.appBackground),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(39, 74, 39, 140),
          child: Column(
            children: [
              _ProfileHeaderCard(
                name: user.fullName,
                email: user.email,
                avatarPath: user.avatarPath,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ProfileSectionCard(
                title: 'Account Settings',
                items: [
                  _ProfileMenuItemData(
                    iconAsset: 'assets/icons/profile/personal_info.svg',
                    label: 'Personal Information',
                    onTap: () => context.push(RoutePaths.profilePersonalInfo),
                  ),
                  _ProfileMenuItemData(
                    iconAsset: 'assets/icons/profile/notifications.svg',
                    label: 'Notifications',
                    onTap: () => context.push(RoutePaths.profileNotifications),
                  ),
                  _ProfileMenuItemData(
                    iconAsset: 'assets/icons/profile/change_password.svg',
                    label: 'Change Password',
                    onTap: () => context.push(RoutePaths.profileChangePassword),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileSectionCard(
                title: 'Support',
                items: [
                  _ProfileMenuItemData(
                    iconAsset: 'assets/icons/profile/help_center.svg',
                    label: 'Help Center',
                    onTap: () => context.push(RoutePaths.profileHelpCenter),
                  ),
                  _ProfileMenuItemData(
                    iconAsset: 'assets/icons/profile/about.svg',
                    label: 'About Confindant',
                    onTap: () => context.push(RoutePaths.profileAbout),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCardContainer(
                radius: AppRadius.md,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: _ProfileMenuTile(
                  item: _ProfileMenuItemData(
                    iconAsset: 'assets/icons/profile/logout.svg',
                    label: 'Logout',
                    iconTint: AppColors.accentAction,
                    labelColor: AppColors.accentAction,
                    onTap: () => _showLogoutSheet(context, ref),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Confindant v1.0.0',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '(c) 2026 All rights reserved',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.70),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return LogoutConfirmSheet(
          onCancel: () => Navigator.of(ctx).pop(),
          onConfirm: () {
            ref.read(isAuthenticatedProvider.notifier).state = false;
            ref.read(authControllerProvider.notifier).logout();
            Navigator.of(ctx).pop();
            context.go(RoutePaths.login);
          },
        );
      },
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.email,
    required this.avatarPath,
  });

  final String name;
  final String email;
  final String avatarPath;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blue600, width: 2),
              image: DecorationImage(
                image: _avatarImageProvider(avatarPath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const _AssetIcon(
                      path: 'assets/icons/profile/edit_vec1.svg',
                      size: 16,
                      color: AppColors.accentAction,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const _AssetIcon(
                      path: 'assets/icons/profile/mail.svg',
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          color: Colors.black,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

ImageProvider _avatarImageProvider(String avatarPath) {
  if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
    return NetworkImage(avatarPath);
  }
  return AssetImage(avatarPath);
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({required this.title, required this.items});

  final String title;
  final List<_ProfileMenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      radius: AppRadius.lg,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.blue600,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Text(
              title,
              style: AppTextStyles.label.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _ProfileMenuTile(item: items[i]),
                  if (i != items.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.item});

  final _ProfileMenuItemData item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              _AssetIcon(
                path: item.iconAsset,
                size: 18,
                color: item.iconTint ?? AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextStyles.body.copyWith(
                    color: item.labelColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _AssetIcon(
                path: 'assets/icons/profile/chevron_right.svg',
                size: 16,
                color: item.labelColor ?? AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetIcon extends StatelessWidget {
  const _AssetIcon({
    required this.path,
    required this.size,
    required this.color,
  });

  final String path;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (context) =>
          Icon(Icons.circle_outlined, size: size, color: color),
    );
  }
}

class _ProfileMenuItemData {
  const _ProfileMenuItemData({
    required this.iconAsset,
    required this.label,
    required this.onTap,
    this.iconTint,
    this.labelColor,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  final Color? iconTint;
  final Color? labelColor;
}
