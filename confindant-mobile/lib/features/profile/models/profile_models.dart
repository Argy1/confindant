class ProfileUserData {
  const ProfileUserData({
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    required this.currency,
    required this.avatarPath,
  });

  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String currency;
  final String avatarPath;

  ProfileUserData copyWith({
    String? fullName,
    String? username,
    String? email,
    String? phone,
    String? currency,
    String? avatarPath,
  }) {
    return ProfileUserData(
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}

class NotificationSettings {
  const NotificationSettings({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.transactionAlerts,
    required this.budgetAlerts,
    required this.weeklyReport,
  });

  final bool pushEnabled;
  final bool emailEnabled;
  final bool transactionAlerts;
  final bool budgetAlerts;
  final bool weeklyReport;

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? transactionAlerts,
    bool? budgetAlerts,
    bool? weeklyReport,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      transactionAlerts: transactionAlerts ?? this.transactionAlerts,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      weeklyReport: weeklyReport ?? this.weeklyReport,
    );
  }
}

class HelpFaqItem {
  const HelpFaqItem({
    required this.question,
    required this.answer,
    this.expanded = false,
  });

  final String question;
  final String answer;
  final bool expanded;

  HelpFaqItem copyWith({bool? expanded}) {
    return HelpFaqItem(
      question: question,
      answer: answer,
      expanded: expanded ?? this.expanded,
    );
  }
}

class AboutInfoData {
  const AboutInfoData({
    required this.appName,
    required this.version,
    required this.build,
    required this.description,
  });

  final String appName;
  final String version;
  final String build;
  final String description;
}

class ProfileNotificationItem {
  const ProfileNotificationItem({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
}

class ProfileSettingsState {
  const ProfileSettingsState({
    required this.userData,
    required this.notificationSettings,
    required this.faqItems,
    required this.aboutInfo,
    required this.recentNotifications,
  });

  final ProfileUserData userData;
  final NotificationSettings notificationSettings;
  final List<HelpFaqItem> faqItems;
  final AboutInfoData aboutInfo;
  final List<ProfileNotificationItem> recentNotifications;

  ProfileSettingsState copyWith({
    ProfileUserData? userData,
    NotificationSettings? notificationSettings,
    List<HelpFaqItem>? faqItems,
    AboutInfoData? aboutInfo,
    List<ProfileNotificationItem>? recentNotifications,
  }) {
    return ProfileSettingsState(
      userData: userData ?? this.userData,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      faqItems: faqItems ?? this.faqItems,
      aboutInfo: aboutInfo ?? this.aboutInfo,
      recentNotifications: recentNotifications ?? this.recentNotifications,
    );
  }
}

class PasswordRuleStatus {
  const PasswordRuleStatus({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSymbol,
    required this.confirmMatches,
  });

  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSymbol;
  final bool confirmMatches;

  bool get isValid =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasNumber &&
      hasSymbol &&
      confirmMatches;
}
