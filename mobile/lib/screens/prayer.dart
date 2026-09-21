import 'dart:async';
import 'package:flutter/material.dart';
import '../core/settings.dart';
import '../core/prayer.dart';
import '../data/cities.dart';

class PrayerScreen extends StatefulWidget {
  final AppSettings settings;
  final Map<String, String>? timings;
  final bool loading;
  final Future<void> Function() onRefresh;
  const PrayerScreen({super.key, required this.settings, required this.timings, required this.loading, required this.onRefresh});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  late Timer _t;
  DateTime now = DateTime.now();
  List<Map<String, dynamic>>? month;
  bool monthLoading = false;
  bool showMonth = false;
  final countryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() => now = DateTime.now()) : null);
    countryCtrl.text = widget.settings.countryAr;
  }

  @override
  void dispose() {
    _t.cancel();
    countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMonth() async {
    if (month != null) {
      setState(() => showMonth = !showMonth);
      return;
    }
    setState(() => monthLoading = true);
    try {
      final s = widget.settings;
      final m = await fetchMonthly(
        city: s.city, country: s.country, method: s.method, madhab: s.madhab,
        useCoords: s.useCoords, lat: s.lat, lng: s.lng,
      );
      if (mounted) {
        setState(() {
          month = m;
          showMonth = true;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.settings.tr('تعذّر تحميل الجدول الشهري', 'Failed to load monthly table'))));
      }
    }
    if (mounted) setState(() => monthLoading = false);
  }

  void _pickCity(String ar) {
    final s = widget.settings;
    CityEntry? found;
    for (final c in popularCities) {
      if (c.ar == ar.trim()) found = c;
    }
    if (found != null) {
      final f = found;
      s.update((x) {
        x.cityAr = f.ar; x.city = f.city; x.country = f.country; x.countryAr = f.countryAr; x.useCoords = false;
      });
      countryCtrl.text = f.countryAr;
    } else {
      s.update((x) => x.cityAr = ar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final t = widget.timings;
    final next = t == null ? null : getNextPrayer(t, now);
    final methodName = calcMethods.firstWhere((m) => m.id == s.method, orElse: () => calcMethods[4]);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(child: Text('🕌 ${s.tr('مواقيت الصلاة', 'Prayer times')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            ElevatedButton(
              onPressed: () => widget.onRefresh(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white),
              child: Text(widget.loading ? '⏳...' : '🔄 ${s.tr('تحديث', 'Refresh')}'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('📍 ${s.cityAr} — ${s.countryAr} • ${s.tr('طريقة الحساب', 'Method')}: ${s.tr(methodName.ar, methodName.en)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFF047857).withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 ${s.tr('غيّر مدينتك — تتحدث المواقيت تلقائياً', 'Change city — times update automatically')}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<String>(
                        initialValue: TextEditingValue(text: s.cityAr),
                        optionsBuilder: (v) {
                          if (v.text.isEmpty) return popularCities.map((c) => c.ar);
                          return popularCities.where((c) => c.ar.contains(v.text)).map((c) => c.ar);
                        },
                        onSelected: (v) {
                          _pickCity(v);
                          widget.onRefresh();
                        },
                        fieldViewBuilder: (ctx, ctrl, focus, done) {
                          return TextField(
                            controller: ctrl,
                            focusNode: focus,
                            decoration: InputDecoration(
                              hintText: s.tr('المدينة', 'City'),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: (v) {
                              _pickCity(v);
                              widget.onRefresh();
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: countryCtrl,
                        decoration: InputDecoration(
                          hintText: s.tr('الدولة', 'Country'),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (v) {
                          s.update((x) => x.countryAr = v);
                          widget.onRefresh();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (t != null && next != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF047857), Color(0xFF0D9488)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(s.tr('الصلاة القادمة', 'Next prayer'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('${next.icon} ${s.tr(next.ar, next.en)} ${t[next.key] ?? ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
                  child: Text('⏳ ${countdownTo(t[next.key] ?? '', now)}',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (t != null)
          for (final p in prayers)
            Card(
              color: next?.key == p.key ? const Color(0xFFECFDF5) : null,
              child: ListTile(
                leading: Text(p.icon, style: const TextStyle(fontSize: 28)),
                title: Text(s.tr(p.ar, p.en), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(t[p.key] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (next?.key == p.key)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF047857), borderRadius: BorderRadius.circular(12)),
                        child: Text(s.tr('القادمة', 'Next'), style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    IconButton(
                      icon: Text((s.prayerNotifs[p.key] ?? false) ? '🔔' : '🔕', style: const TextStyle(fontSize: 22)),
                      onPressed: () => s.update((x) => x.prayerNotifs[p.key] = !(x.prayerNotifs[p.key] ?? false)),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: monthLoading ? null : _loadMonth,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
          child: Text(monthLoading ? '⏳...' : '📅 ${s.tr('الجدول الشهري للمواقيت', 'Monthly timetable')}'),
        ),
        if (showMonth && month != null) ...[
          const SizedBox(height: 8),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF047857)),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                dataRowMinHeight: 30,
                dataRowMaxHeight: 30,
                columns: [
                  DataColumn(label: Text(s.tr('اليوم', 'Day'))),
                  for (final p in prayers) DataColumn(label: Text(s.tr(p.ar, p.en))),
                ],
                rows: [
                  for (final d in month!)
                    DataRow(cells: [
                      DataCell(Text(d['day'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                      for (final p in prayers) DataCell(Text((d['timings'] as Map)[p.key].toString())),
                    ]),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(16)),
          child: Text(
            '💡 ${s.tr('اضغط على 🔔 بجانب كل صلاة لتفعيل التنبيه أو كتمه. لتعديل وقت صلاة بدقة اذهب للإعدادات ← تعديل المواقيت يدوياً. الجدول الشهري يعرض الأوقات الفلكية التلقائية.', 'Tap 🔔 to enable/mute each prayer alert. Set exact times in Settings. Monthly table shows automatic times.')}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
          ),
        ),
        const SizedBox(height: 70),
      ],
    );
  }
}
