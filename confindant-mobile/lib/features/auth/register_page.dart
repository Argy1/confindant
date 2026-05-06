import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => loading = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .register(
          username: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
        );
    if (!mounted) return;
    setState(() => loading = false);

    if (ok) {
      context.go(RoutePaths.home);
      return;
    }

    final message =
        ref.read(authControllerProvider).errorMessage ?? l10n.authRegisterFailed;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppGradientScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 345),
            child: AppCardContainer(
              radius: AppRadius.xl,
              useElevatedShadow: true,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: LanguageSwitcherButton(
                      iconColor: AppColors.accentAction,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accentAction,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Center(
                      child: const AppLineIcon(
                        kind: AppLineIconKind.wallet,
                        color: AppColors.white,
                        size: 44,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.registerCreateAccount,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.registerSubtitle,
                    style: AppTextStyles.body.copyWith(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    controller: nameController,
                    labelText: l10n.registerFullName,
                    hintText: l10n.registerNameHint,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: emailController,
                    labelText: l10n.registerEmail,
                    hintText: l10n.registerEmailHint,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPasswordField(
                    controller: passwordController,
                    labelText: l10n.registerPassword,
                    hintText: l10n.registerPasswordHint,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPrimaryButton(
                    label: l10n.registerCreateAccount,
                    isLoading: loading,
                    onPressed: loading ? null : _createAccount,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        l10n.registerHaveAccount,
                        style: AppTextStyles.body.copyWith(fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: () => context.go(RoutePaths.login),
                        child: Text(
                          l10n.loginSignIn,
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.accentAction,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
