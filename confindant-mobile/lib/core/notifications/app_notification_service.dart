import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationService {
  AppNotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    final macosGranted = await macos?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? true) &&
        (iosGranted ?? true) &&
        (macosGranted ?? true);
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'confindant_general',
        'General Notifications',
        channelDescription: 'General alerts from Confindant',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _plugin.show(id, title, body, details);
  }
}
