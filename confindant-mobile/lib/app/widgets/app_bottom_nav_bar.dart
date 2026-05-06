import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/app_glass_container.dart';
import 'package:flutter/material.dart';

enum AppNavItem { home, analytics, scan, wallet, profile }

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.current,
    required this.onItemSelected,
    required this.onScanTap,
  });

  final AppNavItem current;
  final ValueChanged<AppNavItem> onItemSelected;
  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 3,
            child: AppGlassContainer(
              radius: 25,
              blurSigma: 5,
              padding: const EdgeInsets.fromLTRB(8, 12.5, 8, 28),
              child: Row(
                children: [
                  _item(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    selected: current == AppNavItem.home,
                    onTap: () => onItemSelected(AppNavItem.home),
                  ),
                  _item(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Analytics',
                    selected: current == AppNavItem.analytics,
                    onTap: () => onItemSelected(AppNavItem.analytics),
                  ),
                  const Spacer(),
                  _item(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet',
                    selected: current == AppNavItem.wallet,
                    onTap: () => onItemSelected(AppNavItem.wallet),
                  ),
                  _item(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    selected: current == AppNavItem.profile,
                    onTap: () => onItemSelected(AppNavItem.profile),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: -14,
            child: Center(
              child: GestureDetector(
                onTap: onScanTap,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: AppGradients.scanFab,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.white),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.textOnDark, size: 36),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textOnDark,
                fontSize: 17,
                height: 22 / 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
