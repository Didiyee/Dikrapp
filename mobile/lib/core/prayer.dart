import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PrayerMeta {
  final String key, ar, en, icon;
  const PrayerMeta(this.key, this.ar, this.en, this.icon);
}

const List<PrayerMeta> prayers = [
  PrayerMeta('Fajr', 'الفجر', 'Fajr', '🌅'),
  PrayerMeta('Dhuhr', 'الظهر', 'Dhuhr', '☀️'),
  PrayerMeta('Asr', 'العصر', 'Asr', '🌤️'),
  PrayerMeta('Maghrib', 'المغرب', 'Maghrib', '🌇'),
  PrayerMeta('Isha', 'العشاء', 'Isha', '🌙'),
];

class CalcMethod {
  final int id; final String ar, en;
  const CalcMethod(this.id, this.ar, this.en);
}

const List<CalcMethod> calcMethods = [
  CalcMethod(0, 'الشيعة الإثنا عشرية', 'Shia Ithna-Ansari'),
  CalcMethod(1, 'جامعة كراتشي', 'Karachi'),
  CalcMethod(2, 'أمريكا الشمالية (ISNA)', 'ISNA'),
  CalcMethod(3, 'رابطة العالم الإسلامي', 'Muslim World League'),
  CalcMethod(4, 'أم القرى (مكة)', 'Umm al-Qura'),
  CalcMethod(5, 'الهيئة المصرية', 'Egyptian Authority'),
  CalcMethod(7, 'طهران', 'Tehran'),
  CalcMethod(8, 'الخليج', 'Gulf'),
  CalcMethod(9, 'الكويت', 'Kuwait'),
  CalcMethod(10, 'قطر', 'Qatar'),
  CalcMethod(13, 'ديوان تركيا', 'Diyanet Turkey'),
  CalcMethod(15, 'فرنسا (UOIF)', 'France UOIF'),
  CalcMethod(16, 'روسيا', 'Russia'),
  CalcMethod(18, 'ماليزيا (JAKIM)', 'Malaysia'),
  CalcMethod(19, 'تونس', 'Tunisia'),
  CalcMethod(20, 'الجزائر', 'Algeria'),
  CalcMethod(21, 'المغرب', 'Morocco'),
];

const _api = 'https://api.aladhan.com/v1';

String _clean(String? t) {
  if (t == null || t.isEmpty) return '--:--';
  final part = t.split(' ').first;
  return part.length >= 5 ? part.substring(0, 5) : part;
}

Future<({Map<String, String> timings, Map<String, dynamic>? hijri})> fetchTimings({
  required String city, required String country, required int method, required int madhab,
  required bool useCoords, required double lat, required double lng,
}) async {
  final school = madhab == 1 ? 1 : 0;
  final Uri url;
  if (useCoords) {
    final now = DateTime.now();
    final d = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    url = Uri.parse('$_api/timings/$d?latitude=$lat&longitude=$lng&method=$method&school=$school');
  } else {
    url = Uri.parse('$_api/timingsByCity?city=${Uri.encodeComponent(city)}&country=${Uri.encodeComponent(country)}&method=$method&school=$school');
  }
  final res = await http.get(url).timeout(const Duration(seconds: 20));
  if (res.statusCode != 200) throw Exception('times');
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  final data = json['data'] as Map<String, dynamic>;
  final t = data['timings'] as Map<String, dynamic>;
  final timings = {for (final p in prayers) p.key: _clean(t[p.key]?.toString())};
  Map<String, dynamic>? hijri;
  try {
    hijri = Map<String, dynamic>.from((data['date'] as Map)['hijri'] as Map);
  } catch (_) {}
  return (timings: timings, hijri: hijri);
}

Future<List<Map<String, dynamic>>> fetchMonthly({
  required String city, required String country, required int method, required int madhab,
  required bool useCoords, required double lat, required double lng,
}) async {
  final school = madhab == 1 ? 1 : 0;
  final now = DateTime.now();
  final mm = now.month.toString().padLeft(2, '0');
  final Uri url = useCoords
      ? Uri.parse('$_api/calendar/${now.year}/$mm?latitude=$lat&longitude=$lng&method=$method&school=$school')
      : Uri.parse('$_api/calendarByCity/${now.year}/$mm?city=${Uri.encodeComponent(city)}&country=${Uri.encodeComponent(country)}&method=$method&school=$school');
  final res = await http.get(url).timeout(const Duration(seconds: 25));
  if (res.statusCode != 200) throw Exception('month');
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  final List data = json['data'] as List;
  return data.map((d) {
    final m = d as Map<String, dynamic>;
    final t = m['timings'] as Map<String, dynamic>;
    final g = m['date']['gregorian'] as Map;
    return {
      'day': g['day'].toString(),
      'timings': {for (final p in prayers) p.key: _clean(t[p.key]?.toString())},
    };
  }).toList();
}

Map<String, String> fallbackTimings() =>
    {'Fajr': '05:00', 'Dhuhr': '12:15', 'Asr': '15:30', 'Maghrib': '18:05', 'Isha': '19:35'};

int toMinutes(String hhmm) {
  final p = hhmm.split(':');
  if (p.length < 2) return 0;
  return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
}

final _timeRe = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

/// Manual exact times set by the user override automatic ones.
Map<String, String> applyCustomTimes(Map<String, String> timings, Map<String, String> custom) {
  final out = Map<String, String>.from(timings);
  for (final k in out.keys) {
    final c = (custom[k] ?? '').trim();
    if (_timeRe.hasMatch(c)) out[k] = c;
  }
  return out;
}

PrayerMeta getNextPrayer(Map<String, String> timings, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final cur = n.hour * 60 + n.minute;
  for (final p in prayers) {
    if (toMinutes(timings[p.key] ?? '') > cur) return p;
  }
  return prayers.first;
}

PrayerMeta getCurrentPrayer(Map<String, String> timings, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final cur = n.hour * 60 + n.minute;
  var curP = prayers.last;
  for (final p in prayers) {
    if (toMinutes(timings[p.key] ?? '') <= cur) curP = p;
  }
  return curP;
}

String countdownTo(String hhmm, [DateTime? now]) {
  final n = now ?? DateTime.now();
  var target = DateTime(n.year, n.month, n.day, toMinutes(hhmm) ~/ 60, toMinutes(hhmm) % 60);
  if (!target.isAfter(n)) target = target.add(const Duration(days: 1));
  final d = target.difference(n);
  String p(int v) => v.toString().padLeft(2, '0');
  return '${p(d.inHours)}:${p(d.inMinutes % 60)}:${p(d.inSeconds % 60)}';
}

String formatHijri(Map<String, dynamic>? hijri, bool isAr) {
  if (hijri == null) {
    try {
      return DateFormat.yMMMMd(isAr ? 'ar_SA' : 'en').format(DateTime.now());
    } catch (_) {
      return '';
    }
  }
  try {
    final month = (hijri['month'] as Map);
    final m = isAr ? month['ar'].toString() : month['en'].toString();
    return isAr ? "${hijri['day']} $m ${hijri['year']}هـ" : "${hijri['day']} $m ${hijri['year']} AH";
  } catch (_) {
    return '';
  }
}

String formatGregorian(bool isAr) {
  try {
    return DateFormat.yMMMMEEEEd(isAr ? 'ar' : 'en').format(DateTime.now());
  } catch (_) {
    return '';
  }
}

double qiblaBearing(double lat, double lng) {
  const kaabaLat = 21.4225 * math.pi / 180;
  const kaabaLng = 39.8262 * math.pi / 180;
  final phi = lat * math.pi / 180;
  final lam = lng * math.pi / 180;
  final dLam = kaabaLng - lam;
  final y = math.sin(dLam);
  final x = math.cos(phi) * math.tan(kaabaLat) - math.sin(phi) * math.cos(dLam);
  final brng = math.atan2(y, x) * 180 / math.pi;
  return (brng + 360) % 360;
}

class AdhanSound {
  final String id, ar, en, url;
  const AdhanSound(this.id, this.ar, this.en, this.url);
}

const List<AdhanSound> adhanSounds = [
  AdhanSound('makkah', 'أذان مكة المكرمة', 'Makkah adhan', 'https://www.islamcan.com/audio/adhan/azan1.mp3'),
  AdhanSound('madinah', 'أذان المدينة المنورة', 'Madinah adhan', 'https://www.islamcan.com/audio/adhan/azan2.mp3'),
  AdhanSound('aqsa', 'أذان الأقصى', 'Al-Aqsa adhan', 'https://www.islamcan.com/audio/adhan/azan3.mp3'),
  AdhanSound('custom', 'رابط مخصص', 'Custom URL', ''),
];

String getAdhanUrl(String id, String customUrl) {
  if (id == 'custom') return customUrl.trim();
  return adhanSounds.firstWhere((s) => s.id == id, orElse: () => adhanSounds.first).url;
}
