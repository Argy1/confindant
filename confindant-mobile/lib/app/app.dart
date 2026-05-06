import 'package:confindant/app/router/app_router.dart';
import 'package:confindant/app/theme/app_theme.dart';
import 'package:confindant/core/localization/language_settings_controller.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfindantApp extends ConsumerWidget {
  const ConfindantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final localeState = ref.watch(languageSettingsProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Confindant',
      theme: AppTheme.light,
      locale: localeState.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
