import 'package:confindant/core/ai/ai_settings_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiSettingsState {
  const AiSettingsState({
    required this.autoCategorizationEnabled,
    this.ready = false,
  });

  final bool autoCategorizationEnabled;
  final bool ready;

  AiSettingsState copyWith({
    bool? autoCategorizationEnabled,
    bool? ready,
  }) {
    return AiSettingsState(
      autoCategorizationEnabled:
          autoCategorizationEnabled ?? this.autoCategorizationEnabled,
      ready: ready ?? this.ready,
    );
  }
}

final aiSettingsStorageProvider = Provider<AiSettingsStorage>((ref) {
  return AiSettingsStorage();
});

final aiSettingsProvider =
    StateNotifierProvider<AiSettingsController, AiSettingsState>((ref) {
  return AiSettingsController(ref.watch(aiSettingsStorageProvider));
});

class AiSettingsController extends StateNotifier<AiSettingsState> {
  AiSettingsController(this._storage)
      : super(const AiSettingsState(autoCategorizationEnabled: true)) {
    _bootstrap();
  }

  final AiSettingsStorage _storage;

  Future<void> _bootstrap() async {
    final enabled = await _storage.readAutoCategorizationEnabled();
    state = state.copyWith(autoCategorizationEnabled: enabled, ready: true);
  }

  Future<void> setAutoCategorizationEnabled(bool enabled) async {
    state = state.copyWith(autoCategorizationEnabled: enabled);
    await _storage.saveAutoCategorizationEnabled(enabled);
  }
}
