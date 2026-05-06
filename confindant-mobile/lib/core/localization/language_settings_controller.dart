import 'dart:ui';

import 'package:confindant/core/localization/language_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageSettingsState {
  const LanguageSettingsState({
    required this.locale,
    this.ready = false,
  });

  final Locale locale;
  final bool ready;

  LanguageSettingsState copyWith({
    Locale? locale,
    bool? ready,
  }) {
    return LanguageSettingsState(
      locale: locale ?? this.locale,
      ready: ready ?? this.ready,
    );
  }
}

final languageStorageProvider = Provider<LanguageStorage>((ref) {
  return LanguageStorage();
});

final languageSettingsProvider =
    StateNotifierProvider<LanguageSettingsController, LanguageSettingsState>((ref) {
      final storage = ref.watch(languageStorageProvider);
      return LanguageSettingsController(storage);
    });

class LanguageSettingsController extends StateNotifier<LanguageSettingsState> {
  LanguageSettingsController(this._storage)
      : super(
          LanguageSettingsState(
            locale: _defaultFromDevice(),
            ready: false,
          ),
        ) {
    _bootstrap();
  }

  final LanguageStorage _storage;

  static Locale _defaultFromDevice() {
    final deviceCode = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return deviceCode == 'id' ? const Locale('id') : const Locale('en');
  }

  Future<void> _bootstrap() async {
    final saved = await _storage.readLanguageCode();
    if (saved == 'id' || saved == 'en') {
      state = state.copyWith(locale: Locale(saved!), ready: true);
      return;
    }
    state = state.copyWith(ready: true);
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'id' && locale.languageCode != 'en') {
      return;
    }
    if (state.locale.languageCode == locale.languageCode) {
      return;
    }
    state = state.copyWith(locale: locale);
    await _storage.saveLanguageCode(locale.languageCode);
  }
}
