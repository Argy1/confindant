import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:confindant/features/profile/models/profile_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ProfileDataSource {
  Future<ProfileSettingsState> fetch();
  Future<ProfileUserData> updateUser(ProfileUserData data);
  Future<ProfileUserData> uploadAvatar(String filePath);
  Future<NotificationSettings> updateNotificationSettings(
    NotificationSettings settings,
  );
}

class ApiProfileDataSource implements ProfileDataSource {
  const ApiProfileDataSource(this._api);

  final BackendApiService _api;

  @override
  Future<ProfileSettingsState> fetch() async {
    final raw = await _api.profile();
    return _stateFrom(raw);
  }

  @override
  Future<ProfileUserData> updateUser(ProfileUserData data) async {
    final raw = await _api.updateProfile({
      'full_name': data.fullName,
      'username': data.username,
      'email': data.email,
      'phone': data.phone,
      'currency': data.currency,
      'avatar_path': data.avatarPath,
    });

    return _userFrom(raw);
  }

  @override
  Future<ProfileUserData> uploadAvatar(String filePath) async {
    final raw = await _api.uploadProfileAvatar(filePath: filePath);
    return _userFrom(raw);
  }

  @override
  Future<NotificationSettings> updateNotificationSettings(
    NotificationSettings settings,
  ) async {
    final raw = await _api.updateNotificationSettings({
      'push_enabled': settings.pushEnabled,
      'email_enabled': settings.emailEnabled,
      'transaction_alerts': settings.transactionAlerts,
      'budget_alerts': settings.budgetAlerts,
      'weekly_report': settings.weeklyReport,
    });
    return _notificationFrom(
      Map<String, dynamic>.from(
        raw['notification_settings'] as Map? ?? const {},
      ),
    );
  }

  ProfileSettingsState _stateFrom(Map<String, dynamic> raw) {
    final profile = Map<String, dynamic>.from(
      raw['profile'] as Map? ?? const {},
    );
    final notificationsRaw = (raw['notifications'] as List? ?? const []);

    return ProfileSettingsState(
      userData: _userFrom(profile),
      notificationSettings: _notificationFrom(
        Map<String, dynamic>.from(
          profile['notification_settings'] as Map? ?? const {},
        ),
      ),
      faqItems: ((profile['faq_items'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) {
            final m = Map<String, dynamic>.from(item);
            return HelpFaqItem(
              question: m['question']?.toString() ?? '',
              answer: m['answer']?.toString() ?? '',
              expanded: m['expanded'] == true,
            );
          })
          .toList(),
      aboutInfo: _aboutFrom(
        Map<String, dynamic>.from(profile['about_info'] as Map? ?? const {}),
      ),
      recentNotifications: notificationsRaw.whereType<Map>().map((item) {
        final m = Map<String, dynamic>.from(item);
        return ProfileNotificationItem(
          title: m['title']?.toString() ?? '',
          subtitle: m['subtitle']?.toString() ?? '',
          timeLabel: m['time_label']?.toString() ?? '',
        );
      }).toList(),
    );
  }

  ProfileUserData _userFrom(Map<String, dynamic> profile) {
    return ProfileUserData(
      fullName: profile['full_name']?.toString() ?? '',
      username: profile['username']?.toString() ?? '',
      email: profile['email']?.toString() ?? '',
      phone: profile['phone']?.toString() ?? '',
      currency: profile['currency']?.toString() ?? 'IDR (Rp)',
      avatarPath:
          profile['avatar_path']?.toString() ??
          'assets/avatars/profile_kennedy.jpg',
    );
  }

  NotificationSettings _notificationFrom(Map<String, dynamic> m) {
    return NotificationSettings(
      pushEnabled: m['push_enabled'] == true,
      emailEnabled: m['email_enabled'] == true,
      transactionAlerts: m['transaction_alerts'] == true,
      budgetAlerts: m['budget_alerts'] == true,
      weeklyReport: m['weekly_report'] == true,
    );
  }

  AboutInfoData _aboutFrom(Map<String, dynamic> m) {
    return AboutInfoData(
      appName: m['app_name']?.toString() ?? 'Confindant',
      version: m['version']?.toString() ?? '1.0.0',
      build: m['build']?.toString() ?? '100',
      description: m['description']?.toString() ?? '',
    );
  }
}

final profileDataSourceProvider = Provider<ProfileDataSource>((ref) {
  return ApiProfileDataSource(ref.watch(backendApiServiceProvider));
});
