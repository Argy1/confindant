import 'dart:async';

import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/auth/auth_state.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final auth = ref.read(authControllerProvider);
    if (auth.status == AuthStatus.authenticated) {
      context.go(RoutePaths.home);
      return;
    }
    if (auth.status == AuthStatus.unauthenticated) {
      context.go(RoutePaths.onboarding);
      return;
    }
    _timer = Timer(const Duration(milliseconds: 400), _navigate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const AppGradientScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLineIcon(
              kind: AppLineIconKind.wallet,
              color: AppColors.white,
              size: 56,
              strokeWidth: 3,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Confindant',
              style: AppTextStyles.screenTitle,
            ),
            SizedBox(height: AppSpacing.lg),
            CircularProgressIndicator(color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
