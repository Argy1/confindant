import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/core/localization/language_settings_controller.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageSwitcherButton extends ConsumerWidget {
  const LanguageSwitcherButton({
    super.key,
    this.iconColor = AppColors.white,
    this.backgroundColor = Colors.transparent,
    this.size = 30,
  });

  final Color iconColor;
  final Color backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.language,
      icon: Icon(Icons.language_rounded, color: iconColor, size: size),
      style: IconButton.styleFrom(backgroundColor: backgroundColor),
      onPressed: () => _openSheet(context, ref),
    );
  }

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(languageSettingsProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.languageIndonesian),
                trailing: state.locale.languageCode == 'id'
                    ? const Icon(Icons.check_rounded, color: AppColors.accentAction)
                    : null,
                onTap: () async {
                  await ref.read(languageSettingsProvider.notifier).setLocale(const Locale('id'));
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                title: Text(l10n.languageEnglish),
                trailing: state.locale.languageCode == 'en'
                    ? const Icon(Icons.check_rounded, color: AppColors.accentAction)
                    : null,
                onTap: () async {
                  await ref.read(languageSettingsProvider.notifier).setLocale(const Locale('en'));
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
