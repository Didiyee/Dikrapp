import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/settings.dart';
import '../data/quran_meta.dart';
import '../services/quran.dart' as q;

class QuranScreen extends StatefulWidget {
  final AppSettings settings;
  const QuranScreen({super.key, required this.settings});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  int? view;
  String query = '';
  List<q.QuranAyah>? ayahs;
  bool loading = false;
  int? playingAyah;
  bool playingSurah = false;
  int cached = 0;
  int? dlDone;
  Map<String, int>? lastRead;
  final AudioPlayer _audio = AudioPlayer();
  List<q.QuranAyah>? _queue;
  int _playIndex = -1;
  bool _autoNext = false;

  AppSettings get s => widget.settings;
  String get riwaya => s.quranRiwaya;

  @override
  void initState() {
    super.initState();
    _refreshCached();
    q.getLastRead().then((v) => mounted ? setState(() => lastRead = v) : null);
    _audio.onPlayerComplete.listen((_) async {
      if (!mounted) return;
      if (_autoNext && _queue != null && _playIndex + 1 < _queue!.length) {
        _playIndex++;
        final a = _queue![_playIndex];
        setState(() => playingAyah = a.g);
        try {
          await _audio.play(UrlSource(q.ayahAudioUrl(a.g)));
        } catch (_) {
          setState(() {
            playingAyah = null;
            _queue = null;
          });
        }
      } else {
        setState(() {
          playingAyah = null;
          playingSurah = false;
          _queue = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _refreshCached() async {
    final c = await q.countCachedSurahs(riwaya);
    if (mounted) setState(() => cached = c);
  }

  Future<void> openSurah(int n) async {
    setState(() {
      view = n;
      ayahs = null;
      loading = true;
    });
    await _audio.stop();
    setState(() {
      playingAyah = null;
      playingSurah = false;
    });
    try {
      final a = await q.fetchSurah(n, riwaya);
      if (mounted) {
        setState(() => ayahs = a);
        _refreshCached();
      }
    } catch (_) {
      if (mounted) setState(() => ayahs = []);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _playAyah(q.QuranAyah a, List<q.QuranAyah> all, bool autoNext) async {
    try {
      await _audio.stop();
      _queue = all;
      _playIndex = all.indexWhere((x) => x.g == a.g);
      _autoNext = autoNext;
      setState(() {
        playingAyah = a.g;
        playingSurah = false;
      });
      await _audio.play(UrlSource(q.ayahAudioUrl(a.g)));
    } catch (_) {
      setState(() {
        playingAyah = null;
        _queue = null;
      });
    }
  }

  Future<void> _playSurah() async {
    try {
      await _audio.stop();
      _queue = null;
      _autoNext = false;
      setState(() {
        playingSurah = true;
        playingAyah = null;
      });
      await _audio.play(UrlSource(q.surahAudioUrl(view!, riwaya)));
    } catch (_) {
      setState(() => playingSurah = false);
    }
  }

  Future<void> _downloadAll() async {
    setState(() => dlDone = 0);
    await q.downloadAllQuran(riwaya, (done, total) {
      if (mounted) setState(() => dlDone = done);
    });
    if (mounted) setState(() => dlDone = null);
    _refreshCached();
  }

  @override
  Widget build(BuildContext context) {
    if (view != null) return _reader();
    return _list();
  }

  Widget _riwayaToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          for (final r in const [('hafs', '📜 رواية حفص عن عاصم'), ('warsh', '📜 رواية ورش عن نافع')])
            Expanded(
              child: InkWell(
                onTap: () {
                  s.update((x) => x.quranRiwaya = r.$1);
                  if (view != null) openSurah(view!);
                  _refreshCached();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: riwaya == r.$1 ? const Color(0xFF047857) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(r.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                          color: riwaya == r.$1 ? Colors.white : Colors.grey)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _list() {
    final filtered = surahs.where((x) {
      if (query.trim().isEmpty) return true;
      return x.ar.contains(query.trim()) ||
          x.en.toLowerCase().contains(query.trim().toLowerCase()) ||
          x.n.toString() == query.trim();
    }).toList();
    final rName = riwaya == 'warsh' ? 'ورش عن نافع' : 'حفص عن عاصم';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('📖 ${s.tr('القرآن الكريم كاملاً', 'The Holy Quran')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _riwayaToggle(),
        if (lastRead != null) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => openSurah(lastRead!['surah']!),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF047857), borderRadius: BorderRadius.circular(16)),
              child: Text(
                '🔖 ${s.tr('أكمل القراءة', 'Continue reading')}: ${s.tr('سورة', 'Surah')} ${surahs[lastRead!['surah']! - 1].ar} — ${s.tr('آية', 'verse')} ${lastRead!['ayah']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: s.tr('🔍 ابحث برقم السورة أو اسمها...', 'Search surah...'),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Expanded(child: Text('💾 ${s.tr('محفوظ دون إنترنت ($rName)', 'Offline ($rName)')}: $cached/114',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              if (dlDone != null)
                Text('⏳ $dlDone/114', style: const TextStyle(fontWeight: FontWeight.bold))
              else
                ElevatedButton(
                  onPressed: _downloadAll,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
                  child: Text(s.tr('تحميل المصحف', 'Download'), style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        if (dlDone != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: dlDone! / 114, minHeight: 8),
          ),
        ],
        const SizedBox(height: 8),
        for (final x in filtered)
          Card(
            child: ListTile(
              onTap: () => openSurah(x.n),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF047857), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('${x.n}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              ),
              title: Text('سورة ${x.ar}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${x.en} • ${x.ayahs} ${s.tr('آية', 'verses')} • ${x.makki ? s.tr('مكية', 'Meccan') : s.tr('مدنية', 'Medinan')}',
                  style: const TextStyle(fontSize: 11)),
              trailing: const Text('۞', style: TextStyle(fontSize: 20, color: Color(0xFFF59E0B))),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            riwaya == 'warsh'
                ? '📖 ${s.tr('النص برواية ورش عن نافع — التلاوة: ياسين الجزائري', 'Warsh text — Yassin Al-Jazairi')}'
                : '📖 ${s.tr('النص بالرسم العثماني (حفص) — التلاوة: مشاري العفاسي', 'Uthmani (Hafs) — Mishary Alafasy')}',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),
        const SizedBox(height: 70),
      ],
    );
  }

  Widget _reader() {
    final meta = surahs[view! - 1];
    final rName = riwaya == 'warsh' ? 'ورش عن نافع' : 'حفص عن عاصم';
    final reciter = riwaya == 'warsh' ? 'ياسين الجزائري (ورش)' : 'مشاري العفاسي (حفص)';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              TextButton(onPressed: () => setState(() { view = null; ayahs = null; }), child: Text('→ ${s.tr('السور', 'Surahs')}')),
              Expanded(
                child: Text('📖 ${s.tr('سورة ${meta.ar}', meta.en)}',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _riwayaToggle()),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: (ayahs == null || ayahs!.isEmpty) ? null : _playSurah,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white),
                  child: Text('▶️ ${s.tr('تلاوة السورة كاملة', 'Recite full surah')}'),
                ),
              ),
              if (playingSurah || playingAyah != null)
                IconButton(
                  icon: const Text('⏹️', style: TextStyle(fontSize: 22)),
                  onPressed: () async {
                    await _audio.stop();
                    setState(() {
                      playingSurah = false;
                      playingAyah = null;
                    });
                  },
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    IconButton(icon: const Text('أ−'), onPressed: () => s.update((x) => x.quranFontSize = (x.quranFontSize - 2).clamp(16, 34))),
                    Text('${s.quranFontSize.toInt()}', style: const TextStyle(fontSize: 12)),
                    IconButton(icon: const Text('أ+'), onPressed: () => s.update((x) => x.quranFontSize = (x.quranFontSize + 2).clamp(16, 34))),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : (ayahs == null || ayahs!.isEmpty)
                  ? Center(child: Text(s.tr('تعذّر التحميل — تحقق من الإنترنت', 'Failed to load — check internet')))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                Text('📜 ${s.tr('النص برواية $rName', '$rName text')}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                                if (view != 1 && view != 9)
                                  Text(bismillah, textAlign: TextAlign.center,
                                      style: GoogleFonts.amiri(fontSize: 24, height: 2, color: const Color(0xFF047857))),
                                const SizedBox(height: 8),
                                RichText(
                                  textAlign: TextAlign.justify,
                                  text: TextSpan(
                                    style: GoogleFonts.amiri(
                                      fontSize: s.quranFontSize, height: 2.2,
                                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                                    ),
                                    children: [
                                      for (final a in ayahs!) ...[
                                        WidgetSpan(
                                          child: InkWell(
                                            onTap: () {
                                              q.setLastRead(view!, a.n);
                                              q.getLastRead().then((v) => mounted ? setState(() => lastRead = v) : null);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 2),
                                              decoration: playingAyah == a.g
                                                  ? BoxDecoration(color: Colors.amber.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(6))
                                                  : null,
                                              child: Text(a.text, style: GoogleFonts.amiri(fontSize: s.quranFontSize, height: 2.2)),
                                            ),
                                          ),
                                        ),
                                        const TextSpan(text: ' '),
                                        if (riwaya == 'hafs')
                                          WidgetSpan(
                                            alignment: PlaceholderAlignment.middle,
                                            child: InkWell(
                                              onTap: () => playingAyah == a.g
                                                  ? _audio.stop().then((_) => mounted ? setState(() => playingAyah = null) : null)
                                                  : _playAyah(a, ayahs!, false),
                                              child: Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: const Color(0xFF047857)),
                                                  borderRadius: BorderRadius.circular(20),
                                                  color: playingAyah == a.g ? const Color(0xFF047857) : null,
                                                ),
                                                child: Text(
                                                  playingAyah == a.g ? '⏸' : '﴿${q.arDigits(a.n)}﴾ 🔊',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: playingAyah == a.g ? Colors.white : const Color(0xFF047857),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          TextSpan(
                                            text: '﴿${q.arDigits(a.n)}﴾ ',
                                            style: const TextStyle(color: Color(0xFFB45309)),
                                          ),
                                        const TextSpan(text: ' '),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text('📖 ${s.tr('اضغط على أي آية لحفظ موضع القراءة', 'Tap any verse to save position')} • 🔊 $reciter',
                                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}
