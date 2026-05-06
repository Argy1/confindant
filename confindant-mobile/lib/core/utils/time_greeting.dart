import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String timeGreeting(BuildContext context, [DateTime? now]) {
  final l10n = AppLocalizations.of(context)!;
  final hour = (now ?? DateTime.now()).hour;
  if (hour >= 5 && hour < 12) {
    return l10n.greetingMorning;
  }
  if (hour >= 12 && hour < 18) {
    return l10n.greetingAfternoon;
  }
  return l10n.greetingEvening;
}

String formatRealtimeDateLabel(BuildContext context, [DateTime? now]) {
  final date = now ?? DateTime.now();
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('EEEE, d MMMM y', locale).format(date);
}
