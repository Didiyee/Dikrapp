import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/settings.dart';
import '../core/prayer.dart';
import '../data/adhkar.dart';

class HomeScreen extends StatefulWidget {
  final AppSettings settings;
  final Map<String, String>? timings;
  final Map<String, dynamic>? hijri;
  final void Function(String to) go;
  const HomeScreen({super.key, required this.settings, required this.timings, required this.hijri, required this.go});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _t;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() => now = DateTime.now()) : null);
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final t = widget.timings;
    final next = t == null ? null : getNextPrayer(t, now);
    final cur = t == null ? null : getCurrentPrayer(t, now);
    final hour = now.hour;
    final greet = s.isAr
        ? (hour < 12 ? '🌅 صباح الخير — السلام عليكم' : hour < 18 ? '☀️ مساء النور — السلام عليكم' : '🌙 مساء الخير — السلام عليكم')
        : (hour < 12 ? 'Good morning' : 'Good evening');
    final dayIdx = DateTime.now().millisecondsSinceEpoch ~/ 86400000;
    final ayah = dailyAyat[dayIdx % dailyAyat.length];

    String? suggest;
    if (t != null) {
      final curM = now.hour * 60 + now.minute;
      if (curM >= toMinutes(t['Fajr'] ?? '') && curM < toMinutes(t['Dhuhr'] ?? '')) {
        suggest = 'morning';
      } else if (curM >= toMinutes(t['Asr'] ?? '')) {
        suggest = 'evening';
      } else if (curM >= 21 * 60 || curM < toMinutes(t['Fajr'] ?? '')) {
        suggest = 'sleep';
      } else {
        suggest = 'afterPrayer';
      }
    }
    AdhkarCat? suggestCat;
    if (suggest != null) {
      suggestCat = adhkarCats.firstWhere((c) => c.id == suggest);
    }

    final quick = [
      {'label': s.tr('مواقيت الصلاة', 'Prayer'), 'icon': '🕌', 'to': 'prayer', 'c1': const Color(0xFF10B981), 'c2': const Color(0xFF0D9488)},
      {'label': s.tr('أذكار الصباح', 'Morning'), 'icon': '🌅', 'to': 'adhkar:morning', 'c1': const Color(0xFFFBBF24), 'c2': const Color(0xFFF97316)},
      {'label': s.tr('أذكار المساء', 'Evening'), 'icon': '🌇', 'to': 'adhkar:evening', 'c1': const Color(0xFF38BDF8), 'c2': const Color(0xFF4F46E5)},
      {'label': s.tr('بعد الصلاة', 'After prayer'), 'icon': '🤲', 'to': 'adhkar:afterPrayer', 'c1': const Color(0xFFA78BFA), 'c2': const Color(0xFF7C3AED)},
      {'label': s.tr('القرآن الكريم', 'Quran'), 'icon': '📖', 'to': 'quran', 'c1': const Color(0xFF10B981), 'c2': const Color(0xFF15803D)},
      {'label': s.tr('اتجاه القبلة', 'Qibla'), 'icon': '🧭', 'to': 'qibla', 'c1': const Color(0xFFFB7185), 'c2': const Color(0xFFE11D48)},
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF047857), Color(0xFF0D9488), Color(0xFF047857)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greet, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(formatGregorian(s.isAr), style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text('🗓️ ${formatHijri(widget.hijri, s.isAr)}', style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 13, fontWeight: FontWeight.bold)),
              Text('📍 ${s.cityAr} — ${s.countryAr}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (t != null && next != null && cur != null)
          Row(
            children: [
              Expanded(
                child: _prayerCard(s.tr('الصلاة الحالية', 'Current'), cur.icon, s.tr(cur.ar, cur.en), t[cur.key] ?? '',
                    const Color(0xFFECFDF5), const Color(0xFF047857)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _prayerCard(s.tr('الصلاة القادمة', 'Next'), next.icon, s.tr(next.ar, next.en),
                    '${t[next.key] ?? ''}\n⏳ ${countdownTo(t[next.key] ?? '', now)}',
                    const Color(0xFFFEF3C7), const Color(0xFFB45309)),
              ),
            ],
          ),
        if (t != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final p in prayers)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: next?.key == p.key ? const Color(0xFF047857) : Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(p.icon, style: const TextStyle(fontSize: 18)),
                            Text(s.tr(p.ar, p.en),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                    color: next?.key == p.key ? Colors.white : null)),
                            Text(t[p.key] ?? '',
                                style: TextStyle(fontSize: 11, color: next?.key == p.key ? Colors.white : null)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text('⚡ ${s.tr('وصول سريع', 'Quick access')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.25,
          children: [
            for (final q in quick)
              InkWell(
                onTap: () => widget.go(q['to'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [q['c1'] as Color, q['c2'] as Color]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(q['icon'] as String, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(q['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (suggestCat != null) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => widget.go('adhkar:${suggestCat!.id}'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF047857).withValues(alpha: 0.08),
                border: Border.all(color: const Color(0xFF047857), width: 1.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Text(suggestCat.icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔔 ${s.tr('حان وقت', 'Time for')} ${s.tr(suggestCat.ar, suggestCat.en)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                        Text(s.tr('اضغط لبدء الذكر الآن — لا تنسَ أذكارك', 'Tap to start now'),
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF065F46), Color(0xFF0F172A)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text('✨ ${s.tr('آية اليوم', "Today's verse")}', style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(ayah['text']!, textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(fontSize: 20, height: 2, color: Colors.white)),
              const SizedBox(height: 6),
              Text(ayah['ref']!, style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _miniCard('⭐', s.tr('المفضلة', 'Bookmarks'), '${s.favorites.length} ${s.tr('ذكر محفوظ', 'saved')}', () => widget.go('adhkar:fav')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniCard('📝', s.tr('دفتر الملاحظات', 'Booknotes'), '${s.notes.length} ${s.tr('ملاحظة', 'notes')}', () => widget.go('adhkar:notes')),
            ),
          ],
        ),
        const SizedBox(height: 70),
      ],
    );
  }

  Widget _prayerCard(String title, String icon, String name, String time, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(icon, style: const TextStyle(fontSize: 26)),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: fg)),
          Text(time, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _miniCard(String icon, String title, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
