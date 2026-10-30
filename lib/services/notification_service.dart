import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Cevap verilmesi gereken evraklar için yerel (internetsiz) hatırlatma bildirimleri.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Hatırlatmalar',
      channelDescription: 'Evraka cevap verme hatırlatmaları',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Saat dilimi okunamazsa uygulamanın hedef ülkesi Almanya varsayılır.
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  /// İlk hatırlatma kurulurken izin istenir (Android 13+ ve iOS).
  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    await cancel(id);
    if (!when.isAfter(DateTime.now())) return;
    await requestPermissions();
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details,
      // Kesin alarm izni gerektirmez; birkaç dakikalık sapma hatırlatma için yeterli.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id: id);
}
