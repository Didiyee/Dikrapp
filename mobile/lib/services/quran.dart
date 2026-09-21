import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quran_meta.dart';

class QuranAyah {
  final int g, n;
  final String text;
  const QuranAyah(this.g, this.n, this.text);
}

final Map<int, int> _offsets = (() {
  final o = <int, int>{};
  var acc = 0;
  for (final s in surahs) {
    o[s.n] = acc;
    acc = acc + s.ayahs;
  }
  return o;
})();

Future<Directory> _quranDir() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/quran');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

Future<List<QuranAyah>?> _readCache(int n, String riwaya) async {
  try {
    final dir = await _quranDir();
    final f = File('${dir.path}/${riwaya}_$n.json');
    if (!await f.exists()) return null;
    final List data = json.decode(await f.readAsString()) as List;
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return QuranAyah((m['g'] as num).toInt(), (m['n'] as num).toInt(), m['text'].toString());
    }).toList();
  } catch (_) {
    return null;
  }
}

Future<void> _writeCache(int n, String riwaya, List<QuranAyah> ayahs) async {
  try {
    final dir = await _quranDir();
    final f = File('${dir.path}/${riwaya}_$n.json');
    await f.writeAsString(json.encode(ayahs.map((a) => {'g': a.g, 'n': a.n, 'text': a.text}).toList()));
  } catch (_) {}
}

Future<List<QuranAyah>> fetchSurah(int n, String riwaya) async {
  final cached = await _readCache(n, riwaya);
  if (cached != null) return cached;
  late final List<QuranAyah> ayahs;
  if (riwaya == 'warsh') {
    final res = await http.get(Uri.parse('https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ara-quranwarsh/$n.min.json')).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) throw Exception('load');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final List ch = json['chapter'] as List;
    ayahs = ch.map((v) {
      final m = v as Map<String, dynamic>;
      final verse = (m['verse'] as num).toInt();
      return QuranAyah(_offsets[n]! + verse, verse, m['text'].toString());
    }).toList();
  } else {
    final res = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah/$n/quran-uthmani')).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) throw Exception('load');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final List arr = (json['data'] as Map)['ayahs'] as List;
    ayahs = arr.map((a) {
      final m = a as Map<String, dynamic>;
      return QuranAyah((m['number'] as num).toInt(), (m['numberInSurah'] as num).toInt(), m['text'].toString());
    }).toList();
  }
  await _writeCache(n, riwaya, ayahs);
  return ayahs;
}

Future<void> downloadAllQuran(String riwaya, void Function(int done, int total) onProgress) async {
  for (var n = 1; n <= 114; n++) {
    try {
      await fetchSurah(n, riwaya);
    } catch (_) {}
    onProgress(n, 114);
  }
}

Future<int> countCachedSurahs(String riwaya) async {
  var c = 0;
  try {
    final dir = await _quranDir();
    for (var n = 1; n <= 114; n++) {
      if (await File('${dir.path}/${riwaya}_$n.json').exists()) c++;
    }
  } catch (_) {}
  return c;
}

Future<Map<String, int>?> getLastRead() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('quran-lastread');
    if (raw == null) return null;
    final m = json.decode(raw) as Map<String, dynamic>;
    return {'surah': (m['surah'] as num).toInt(), 'ayah': (m['ayah'] as num).toInt()};
  } catch (_) {
    return null;
  }
}

Future<void> setLastRead(int surah, int ayah) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quran-lastread', json.encode({'surah': surah, 'ayah': ayah}));
  } catch (_) {}
}

String ayahAudioUrl(int globalNum) => 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalNum.mp3';

String surahAudioUrl(int n, String riwaya) => riwaya == 'warsh'
    ? 'https://cdn.islamic.network/quran/audio-surah/128/ar.yassenaljazairi/$n.mp3'
    : 'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$n.mp3';

String arDigits(int n) => n.toString().split('').map((d) {
      const m = {'0': '٠', '1': '١', '2': '٢', '3': '٣', '4': '٤', '5': '٥', '6': '٦', '7': '٧', '8': '٨', '9': '٩'};
      return m[d] ?? d;
    }).join();
