import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum WorkspaceMode { personal, org }

class WorkspaceState {
  const WorkspaceState({
    this.mode = WorkspaceMode.personal,
    this.activeOrgId,
    this.hydrated = false,
  });

  final WorkspaceMode mode;
  final String? activeOrgId;
  final bool hydrated;

  bool get isOrg => mode == WorkspaceMode.org;

  WorkspaceState copyWith({
    WorkspaceMode? mode,
    String? activeOrgId,
    bool? hydrated,
  }) {
    return WorkspaceState(
      mode: mode ?? this.mode,
      activeOrgId: activeOrgId ?? this.activeOrgId,
      hydrated: hydrated ?? this.hydrated,
    );
  }
}

/// Holds the active workspace (Personal vs an Organization) and persists the
/// choice so the app reopens in the same context.
class WorkspaceController extends StateNotifier<WorkspaceState> {
  WorkspaceController() : super(const WorkspaceState()) {
    _restore();
  }

  static const _storage = FlutterSecureStorage();
  static const _modeKey = 'workspace_mode';
  static const _orgKey = 'workspace_org_id';

  Future<void> _restore() async {
    try {
      final mode = await _storage.read(key: _modeKey);
      final orgId = await _storage.read(key: _orgKey);
      state = state.copyWith(
        mode: mode == 'org' ? WorkspaceMode.org : WorkspaceMode.personal,
        activeOrgId: orgId,
        hydrated: true,
      );
    } catch (_) {
      state = state.copyWith(hydrated: true);
    }
  }

  Future<void> switchToPersonal() async {
    state = state.copyWith(mode: WorkspaceMode.personal);
    await _persist();
  }

  Future<void> switchToOrg(String orgId) async {
    state = WorkspaceState(
      mode: WorkspaceMode.org,
      activeOrgId: orgId,
      hydrated: true,
    );
    await _persist();
  }

  Future<void> setActiveOrg(String orgId) async {
    state = state.copyWith(activeOrgId: orgId);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _storage.write(
        key: _modeKey,
        value: state.mode == WorkspaceMode.org ? 'org' : 'personal',
      );
      if (state.activeOrgId != null) {
        await _storage.write(key: _orgKey, value: state.activeOrgId);
      }
    } catch (_) {
      // Ignore storage errors (e.g. in tests).
    }
  }
}

final workspaceControllerProvider =
    StateNotifierProvider<WorkspaceController, WorkspaceState>((ref) {
      return WorkspaceController();
    });

/// The active organization id, defaulting to the first org when unset.
final activeOrgIdProvider = Provider<String?>((ref) {
  final ws = ref.watch(workspaceControllerProvider);
  return ws.activeOrgId;
});
