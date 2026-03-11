import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_shadows.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'Track Your Money',
      subtitle: 'Keep track of all your income and expenses in one place',
      iconKind: AppLineIconKind.wallet,
    ),
    _OnboardingItem(
      title: 'Financial Insights',
      subtitle: 'Get detailed reports and insights about your spending habits',
      iconKind: AppLineIconKind.trend,
    ),
    _OnboardingItem(
      title: 'Budget Management',
      subtitle: 'Set budgets and monitor your spending across categories',
      iconKind: AppLineIconKind.pie,
    ),
    _OnboardingItem(
      title: 'Secure & Private',
      subtitle: 'Your financial data is encrypted and stored securely',
      iconKind: AppLineIconKind.shield,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_index == _items.length - 1) {
      context.go(RoutePaths.login);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientScaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _items.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(32, 74, 32, 0),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Center(
                          child: AppLineIcon(
                            kind: item.iconKind,
                            color: AppColors.accentAction,
                            size: 90,
                            strokeWidth: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.screenTitle.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                          height: 1.55,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                AppIndicatorDots(count: _items.length, activeIndex: _index),
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (_index != _items.length - 1)
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Skip',
                          backgroundColor: AppColors.white.withValues(
                            alpha: 0.2,
                          ),
                          foregroundColor: AppColors.white,
                          onPressed: () => context.go(RoutePaths.login),
                        ),
                      ),
                    if (_index != _items.length - 1)
                      const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: _index == _items.length - 1 ? 2 : 1,
                      child: AppSecondaryButton(
                        label: _index == _items.length - 1
                            ? 'Get Started'
                            : 'Next',
                        icon: _index == _items.length - 1
                            ? null
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.accentAction,
                              ),
                        onPressed: _goNext,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.iconKind,
  });

  final String title;
  final String subtitle;
  final AppLineIconKind iconKind;
}
