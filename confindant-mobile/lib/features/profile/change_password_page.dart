import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/widgets/app_password_field.dart';
import 'package:confindant/app/widgets/app_primary_button.dart';
import 'package:confindant/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:confindant/features/profile/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(
      passwordRuleStatusProvider((
        newPassword: _newController.text,
        confirm: _confirmController.text,
      )),
    );

    return ProfileDetailScaffold(
      title: 'Change Password',
      subtitle: 'Keep your account secure',
      child: Column(
        children: [
          ProfileSettingsCard(
            title: 'Update Password',
            child: Column(
              children: [
                AppPasswordField(
                  controller: _currentController,
                  labelText: 'Current Password',
                  hintText: 'Enter current password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppPasswordField(
                  controller: _newController,
                  labelText: 'New Password',
                  hintText: 'Enter new password',
                  prefixIcon: const Icon(Icons.password_rounded),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppPasswordField(
                  controller: _confirmController,
                  labelText: 'Confirm Password',
                  hintText: 'Confirm new password',
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PasswordRuleChip(
                      label: 'Min 8 chars',
                      valid: status.hasMinLength,
                    ),
                    PasswordRuleChip(
                      label: 'Uppercase',
                      valid: status.hasUppercase,
                    ),
                    PasswordRuleChip(
                      label: 'Lowercase',
                      valid: status.hasLowercase,
                    ),
                    PasswordRuleChip(label: 'Number', valid: status.hasNumber),
                    PasswordRuleChip(label: 'Symbol', valid: status.hasSymbol),
                    PasswordRuleChip(
                      label: 'Match confirm',
                      valid: status.confirmMatches,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppPrimaryButton(
                  label: 'Update Password',
                  onPressed:
                      status.isValid && _currentController.text.isNotEmpty
                      ? () => _submit(context)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password updated (mock).')));
    _currentController.clear();
    _newController.clear();
    _confirmController.clear();
    setState(() {});
  }
}
