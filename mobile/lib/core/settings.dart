import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// App settings persisted in SharedPreferences. Mirrors the web app.
class AppSettings extends ChangeNotifier {
  static const _key = 'salati-settings-v1';

  String city = 'Makkah al-Mukarramah';
  String cityAr = 'مكة المكرمة';
  String country = 'Saudi Arabia';
  String countryAr = 'السعودية';
  int method = 4;
  int madhab = 0; // 0 Shafi, 1 Hanafi
  String lang = 'ar';
  String theme = 'light';
  bool useCoords = false;
  double lat = 21.4225;
  double lng = 39.8262;
  Map<String, bool> prayerNotifs = {'Fajr': true, 'Dhuhr': true, 'Asr': true, 'Maghrib': true, 'Isha': true};
  bool adhkarReminders = true;
  String morningReminder = '05:00';
  String eveningReminder = '16:30';
  String nightReminder = '22:00';
  bool sound = true;
  bool vibration = true;
  bool adhanEnabled = true;
  String adhanSound = 'makkah';
  String adhanCustomUrl = '';
  double adhanVolume = 0.9;
  Map<String, String> customTimes = {'Fajr': '', 'Dhuhr': '', 'Asr': '', 'Maghrib': '', 'Isha': ''};
  List<String> favorites = [];
  Map<String, int> counters = {};
  List<Map<String, String>> notes = [];
  String quranRiwaya = 'hafs';
  double quranFontSize = 22;

  static Future<AppSettings> load() async {
    final s = AppSettings();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return s;
      final m = json.decode(raw) as Map<String, dynamic>;
      s.city = m['city'] ?? s.city;
      s.cityAr = m['cityAr'] ?? s.cityAr;
      s.country = m['country'] ?? s.country;
      s.countryAr = m['countryAr'] ?? s.countryAr;
      s.method = (m['method'] ?? 4) as int;
      s.madhab = (m['madhab'] ?? 0) as int;
      s.lang = m['lang'] ?? 'ar';
      s.theme = m['theme'] ?? 'light';
      s.useCoords = m['useCoords'] ?? false;
      s.lat = ((m['lat'] ?? 21.4225) as num).toDouble();
      s.lng = ((m['lng'] ?? 39.8262) as num).toDouble();
      final pn = m['prayerNotifs'] as Map<String, dynamic>?;
      if (pn != null) {
        for (final k in s.prayerNotifs.keys) {
          if (pn[k] is bool) s.prayerNotifs[k] = pn[k] as bool;
        }
      }
      s.adhkarReminders = m['adhkarReminders'] ?? true;
      s.morningReminder = m['morningReminder'] ?? '05:00';
      s.eveningReminder = m['eveningReminder'] ?? '16:30';
      s.nightReminder = m['nightReminder'] ?? '22:00';
      s.sound = m['sound'] ?? true;
      s.vibration = m['vibration'] ?? true;
      s.adhanEnabled = m['adhanEnabled'] ?? true;
      s.adhanSound = m['adhanSound'] ?? 'makkah';
      s.adhanCustomUrl = m['adhanCustomUrl'] ?? '';
      s.adhanVolume = ((m['adhanVolume'] ?? 0.9) as num).toDouble();
      final ct = m['customTimes'] as Map<String, dynamic>?;
      if (ct != null) {
        for (final k in s.customTimes.keys) {
          s.customTimes[k] = (ct[k] ?? '').toString();
        }
      }
      final fav = m['favorites'] as List?;
      if (fav != null) s.favorites = fav.map((e) => e.toString()).toList();
      final co = m['counters'] as Map<String, dynamic>?;
      if (co != null) s.counters = co.map((k, v) => MapEntry(k, (v as num).toInt()));
      final no = m['notes'] as List?;
      if (no != null) {
        s.notes = no.map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))).toList();
      }
      s.quranRiwaya = m['quranRiwaya'] ?? 'hafs';
      s.quranFontSize = ((m['quranFontSize'] ?? 22) as num).toDouble();
    } catch (_) {}
    return s;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode({
        'city': city, 'cityAr': cityAr, 'country': country, 'countryAr': countryAr,
        'method': method, 'madhab': madhab, 'lang': lang, 'theme': theme,
        'useCoords': useCoords, 'lat': lat, 'lng': lng,
        'prayerNotifs': prayerNotifs, 'adhkarReminders': adhkarReminders,
        'morningReminder': morningReminder, 'eveningReminder': eveningReminder,
        'nightReminder': nightReminder, 'sound': sound, 'vibration': vibration,
        'adhanEnabled': adhanEnabled, 'adhanSound': adhanSound,
        'adhanCustomUrl': adhanCustomUrl, 'adhanVolume': adhanVolume,
        'customTimes': customTimes, 'favorites': favorites, 'counters': counters,
        'notes': notes, 'quranRiwaya': quranRiwaya, 'quranFontSize': quranFontSize,
      }));
    } catch (_) {}
  }

  void update(void Function(AppSettings s) fn) {
    fn(this);
    _save();
    notifyListeners();
  }

  void reset() {
    final fresh = AppSettings();
    city = fresh.city; cityAr = fresh.cityAr; country = fresh.country; countryAr = fresh.countryAr;
    method = fresh.method; madhab = fresh.madhab; lang = fresh.lang; theme = fresh.theme;
    useCoords = fresh.useCoords; lat = fresh.lat; lng = fresh.lng;
    prayerNotifs = fresh.prayerNotifs; adhkarReminders = fresh.adhkarReminders;
    morningReminder = fresh.morningReminder; eveningReminder = fresh.eveningReminder;
    nightReminder = fresh.nightReminder; sound = fresh.sound; vibration = fresh.vibration;
    adhanEnabled = fresh.adhanEnabled; adhanSound = fresh.adhanSound;
    adhanCustomUrl = fresh.adhanCustomUrl; adhanVolume = fresh.adhanVolume;
    customTimes = fresh.customTimes; favorites = fresh.favorites; counters = fresh.counters;
    notes = fresh.notes; quranRiwaya = fresh.quranRiwaya; quranFontSize = fresh.quranFontSize;
    _save();
    notifyListeners();
  }

  bool get isAr => lang == 'ar';
  String tr(String ar, String en) => isAr ? ar : en;
}
