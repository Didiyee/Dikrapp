import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../core/prayer.dart';
import '../core/settings.dart';

final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  await notifications.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );
  tzdata.initializeTimeZones();
  final android = notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();
  await android?.requestExactAlarmsPermission();
  const channel = AndroidNotificationChannel(
    'prayer_channel', 'Prayer & Adhkar',
    description: 'Prayer times and adhkar reminders',
    importance: Importance.max, playSound: true, enableVibration: true,
  );
  await android?.createNotificationChannel(channel);
}

NotificationDetails _details(AppSettings s) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_channel', 'Prayer & Adhkar',
      importance: Importance.max, priority: Priority.high,
      playSound: s.sound, enableVibration: s.vibration,
    ),
    iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );
}

DateTime _todayAt(String hhmm) {
  final now = DateTime.now();
  final parts = hhmm.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  return DateTime(now.year, now.month, now.day, h, m);
}

/// Convert a device-local time to an absolute UTC instant using the
/// device's current UTC offset (no timezone database lookup needed).
tz.TZDateTime _toUtc(DateTime local) =>
    tz.TZDateTime.from(local, tz.UTC).subtract(DateTime.now().timeZoneOffset);

/// Schedule today's remaining prayers + adhkar reminders for the next 7 days.
/// Called on every app start, so schedules stay fresh.
Future<void> scheduleDay(Map<String, String> timings, AppSettings s) async {
  try {
    await notifications.cancelAll();
    final now = DateTime.now();
    var id = 100;
    for (final p in prayers) {
      if (s.prayerNotifs[p.key] != true) continue;
      final at = _todayAt(timings[p.key] ?? '');
      if (!at.isAfter(now)) continue;
      await notifications.zonedSchedule(
        id++, '🕌 ${s.tr('حان وقت الصلاة: صلاة ${p.ar}', 'Prayer time: ${p.en}')}',
        s.tr('حي على الصلاة — تقبّل الله منا ومنكم', 'Come to prayer'),
        _toUtc(at), _details(s),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    if (s.adhkarReminders) {
      final rems = {
        s.morningReminder: s.tr('🌅 حان وقت أذكار الصباح', 'Time for morning adhkar'),
        s.eveningReminder: s.tr('🌇 حان وقت أذكار المساء', 'Time for evening adhkar'),
        s.nightReminder: s.tr('🌙 حان وقت أذكار النوم — لا تنسَ أذكارك', 'Time for sleep adhkar'),
      };
      var rid = 200;
      for (final e in rems.entries) {
        for (var day = 0; day < 7; day++) {
          final at = _todayAt(e.key).add(Duration(days: day));
          if (!at.isAfter(now)) continue;
          await notifications.zonedSchedule(
            rid++, e.value, s.tr('لا تنسَ أذكارك 🤲', 'Do not forget your adhkar'),
            _toUtc(at), _details(s),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    }
  } catch (_) {}
}
