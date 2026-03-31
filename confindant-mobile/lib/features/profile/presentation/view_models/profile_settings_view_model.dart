import 'package:confindant/features/profile/data/profile_data_source.dart';
import 'package:confindant/features/profile/models/profile_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileSettingsProvider =
    StateNotifierProvider<ProfileSettingsViewModel, ProfileSettingsState>((
      ref,
    ) {
      return ProfileSettingsViewModel(ref.watch(profileDataSourceProvider));
    });

final passwordRuleStatusProvider =
    Provider.family<PasswordRuleStatus, ({String newPassword, String confirm})>(
      (ref, args) {
        final newPassword = args.newPassword;
        final confirm = args.confirm;
        return PasswordRuleStatus(
          hasMinLength: newPassword.length >= 8,
          hasUppercase: RegExp(r'[A-Z]').hasMatch(newPassword),
          hasLowercase: RegExp(r'[a-z]').hasMatch(newPassword),
          hasNumber: RegExp(r'[0-9]').hasMatch(newPassword),
          hasSymbol: RegExp(
            r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\]~`]',
          ).hasMatch(newPassword),
          confirmMatches: confirm.isNotEmpty && newPassword == confirm,
        );
      },
    );

class ProfileSettingsViewModel extends StateNotifier<ProfileSettingsState> {
  ProfileSettingsViewModel(this._dataSource) : super(_initial()) {
    _load();
  }

  final ProfileDataSource _dataSource;

  static ProfileSettingsState _initial() {
    return const ProfileSettingsState(
      userData: ProfileUserData(
        fullName: '',
        username: '',
        email: '',
        phone: '',
        currency: 'IDR (Rp)',
        avatarPath: 'assets/avatars/profile_kennedy.jpg',
      ),
      notificationSettings: NotificationSettings(
        pushEnabled: true,
        emailEnabled: true,
        transactionAlerts: true,
        budgetAlerts: true,
        weeklyReport: false,
      ),
      faqItems: [],
      aboutInfo: AboutInfoData(
        appName: 'Confindant',
        version: '1.0.0',
        build: '100',
        description: '',
      ),
      recentNotifications: [],
    );
  }

  Future<void> _load() async {
    try {
      state = await _dataSource.fetch();
    } catch (_) {
      // Keep current fallback state.
    }
  }

  Future<void> updateUser(ProfileUserData data) async {
    state = state.copyWith(userData: data);
    try {
      final updated = await _dataSource.updateUser(data);
      state = state.copyWith(userData: updated);
    } catch (_) {
      // optimistic state retained
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    try {
      final updated = await _dataSource.uploadAvatar(filePath);
      state = state.copyWith(userData: updated);
      return true;
    } catch (_) {
      // keep current avatar
      return false;
    }
  }

  void togglePush(bool value) {
    _persistSettings(state.notificationSettings.copyWith(pushEnabled: value));
  }

  void toggleEmail(bool value) {
    _persistSettings(state.notificationSettings.copyWith(emailEnabled: value));
  }

  void toggleTransactionAlerts(bool value) {
    _persistSettings(
      state.notificationSettings.copyWith(transactionAlerts: value),
    );
  }

  void toggleBudgetAlerts(bool value) {
    _persistSettings(state.notificationSettings.copyWith(budgetAlerts: value));
  }

  void toggleWeeklyReport(bool value) {
    _persistSettings(state.notificationSettings.copyWith(weeklyReport: value));
  }

  Future<void> _persistSettings(NotificationSettings next) async {
    state = state.copyWith(notificationSettings: next);
    try {
      final updated = await _dataSource.updateNotificationSettings(next);
      state = state.copyWith(notificationSettings: updated);
    } catch (_) {
      // optimistic state retained
    }
  }

  void toggleFaqExpanded(int index) {
    final updated = [...state.faqItems];
    final item = updated[index];
    updated[index] = item.copyWith(expanded: !item.expanded);
    state = state.copyWith(faqItems: updated);
  }
}
