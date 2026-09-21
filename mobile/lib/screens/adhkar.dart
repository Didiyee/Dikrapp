import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/settings.dart';
import '../data/adhkar.dart';

final FlutterTts _tts = FlutterTts();

Future<void> speakDhikr(String text) async {
  try {
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.45);
    await _tts.stop();
    await _tts.speak(text);
  } catch (_) {}
}

class AdhkarScreen extends StatefulWidget {
  final AppSettings settings;
  final String initialCat;
  const AdhkarScreen({super.key, required this.settings, required this.initialCat});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  late String tab; // cats | fav | notes
  late String cat;
  String q = '';
  final titleCtrl = TextEditingController();
  final textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCat == 'fav') {
      tab = 'fav';
      cat = 'morning';
    } else if (widget.initialCat == 'notes') {
      tab = 'notes';
      cat = 'morning';
    } else {
      tab = 'cats';
      cat = adhkarCats.any((c) => c.id == widget.initialCat) ? widget.initialCat : 'morning';
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    List<Dhikr> list = allAdhkar.where((d) => d.cat == cat).toList();
    if (q.trim().isNotEmpty) {
      list = allAdhkar.where((d) => d.text.contains(q.trim())).toList();
    }
    final favList = allAdhkar.where((d) => s.favorites.contains(d.id)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Text('📿 ${s.tr('الأذكار', 'Adhkar')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                _tabBtn(s.tr('التصنيفات', 'Categories'), '🗂️', tab == 'cats', () => setState(() => tab = 'cats')),
                _tabBtn('${s.tr('المحفوظات', 'Bookmarks')} (${s.favorites.length})', '⭐', tab == 'fav', () => setState(() => tab = 'fav')),
                _tabBtn('${s.tr('الملاحظات', 'Booknotes')} (${s.notes.length})', '📝', tab == 'notes', () => setState(() => tab = 'notes')),
              ],
            ),
          ),
        ),
        Expanded(
          child: tab == 'notes'
              ? _notesView(s)
              : tab == 'fav'
                  ? _favView(s, favList)
                  : _catsView(s, list),
        ),
      ],
    );
  }

  Widget _tabBtn(String label, String icon, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Theme.of(context).cardColor : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
          ),
          child: Text('$icon $label', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: active ? const Color(0xFF047857) : Colors.grey)),
        ),
      ),
    );
  }

  Widget _catsView(AppSettings s, List<Dhikr> list) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: s.tr('🔍 ابحث في الأذكار...', 'Search adhkar...'),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (v) => setState(() => q = v),
        ),
        if (q.trim().isEmpty) ...[
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: [
              for (final c in adhkarCats)
                InkWell(
                  onTap: () => setState(() => cat = c.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cat == c.id ? const Color(0xFF047857) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c.icon, style: const TextStyle(fontSize: 24)),
                        Text(s.tr(c.ar, c.en), textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                color: cat == c.id ? Colors.white : null)),
                        Text('${allAdhkar.where((d) => d.cat == c.id).length} ${s.tr('ذكر', 'items')}',
                            style: TextStyle(fontSize: 10, color: cat == c.id ? Colors.white70 : Colors.grey)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        for (final d in list) ...[
          DhikrCard(settings: s, dhikr: d),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 70),
      ],
    );
  }

  Widget _favView(AppSettings s, List<Dhikr> favList) {
    if (favList.isEmpty) {
      return Center(child: Text(s.tr('لا توجد محفوظات بعد\n⭐ اضغط على ☆ بجانب أي ذكر لحفظه هنا', 'No bookmarks yet'), textAlign: TextAlign.center));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final d in favList) ...[
          DhikrCard(settings: s, dhikr: d),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 70),
      ],
    );
  }

  Widget _notesView(AppSettings s) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📝 ${s.tr('إضافة ملاحظة جديدة', 'Add a new note')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(hintText: s.tr('العنوان', 'Title'), border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: textCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: s.tr('اكتب ملاحظتك...', 'Write...'), border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (textCtrl.text.trim().isEmpty) return;
                      s.update((x) => x.notes = [
                            {'title': titleCtrl.text.trim().isEmpty ? s.tr('ملاحظة', 'Note') : titleCtrl.text.trim(),
                             'text': textCtrl.text.trim(),
                             'at': DateTime.now().toString().substring(0, 16)},
                            ...x.notes
                          ]);
                      titleCtrl.clear();
                      textCtrl.clear();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                    child: Text('➕ ${s.tr('حفظ الملاحظة', 'Save note')}'),
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final n in s.notes)
          Card(
            color: const Color(0xFFFEF3C7),
            child: ListTile(
              title: Text('📌 ${n['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n['text'] ?? '', style: const TextStyle(height: 1.8)),
                  Text(n['at'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              trailing: IconButton(
                icon: const Text('🗑️', style: TextStyle(fontSize: 18)),
                onPressed: () => s.update((x) => x.notes = x.notes.where((e) => e['at'] != n['at'] || e['text'] != n['text']).toList()),
              ),
            ),
          ),
        const SizedBox(height: 70),
      ],
    );
  }
}

class DhikrCard extends StatelessWidget {
  final AppSettings settings;
  final Dhikr dhikr;
  const DhikrCard({super.key, required this.settings, required this.dhikr});

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final remaining = s.counters[dhikr.id] ?? dhikr.repeat;
    final done = dhikr.repeat - remaining;
    final pct = dhikr.repeat == 0 ? 1.0 : (done / dhikr.repeat).clamp(0.0, 1.0);
    final completed = remaining <= 0;
    final isFav = s.favorites.contains(dhikr.id);

    return Card(
      color: completed ? const Color(0xFFECFDF5) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: completed ? const Color(0xFF047857) : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dhikr.text, style: GoogleFonts.amiri(fontSize: 19, height: 2)),
            if (dhikr.virtue.isNotEmpty)
              Text('✨ ${dhikr.virtue}', style: const TextStyle(fontSize: 12, color: Color(0xFF047857))),
            if (dhikr.source.isNotEmpty)
              Text('📚 ${dhikr.source}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: pct, minHeight: 8,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2), color: const Color(0xFF047857)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: completed
                        ? null
                        : () => s.update((x) => x.counters = {...x.counters, dhikr.id: remaining - 1}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(completed
                        ? '✅ ${s.tr('تم — تقبّل الله', 'Done')}'
                        : '👆 ${s.tr('اضغط للتسبيح', 'Tap to count')} • $remaining/${dhikr.repeat}'),
                  ),
                ),
                IconButton(
                  icon: const Text('🔄', style: TextStyle(fontSize: 20)),
                  onPressed: () => s.update((x) => x.counters = {...x.counters, dhikr.id: dhikr.repeat}),
                ),
                IconButton(
                  icon: Text(isFav ? '⭐' : '☆', style: const TextStyle(fontSize: 22)),
                  onPressed: () => s.update((x) => x.favorites =
                      isFav ? x.favorites.where((e) => e != dhikr.id).toList() : [...x.favorites, dhikr.id]),
                ),
                IconButton(
                  icon: const Text('🔊', style: TextStyle(fontSize: 20)),
                  onPressed: () => speakDhikr(dhikr.text),
                ),
                IconButton(
                  icon: const Text('📋', style: TextStyle(fontSize: 18)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: dhikr.text));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.tr('تم النسخ', 'Copied'))));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
