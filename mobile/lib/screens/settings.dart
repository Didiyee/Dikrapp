import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../core/settings.dart';
import '../core/prayer.dart';
import '../data/cities.dart';
import '../services/notify.dart' as notify;

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final Map<String, String>? autoTimes;
  const SettingsScreen({super.key, required this.settings, required this.autoTimes});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings get s => widget.settings;
  final AudioPlayer _player = AudioPlayer();
  bool testingAdhan = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickTime(String initial, void Function(String v) onPick) async {
    final parts = initial.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 5,
        minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      ),
    );
    if (t != null) {
      onPick('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('⚙️ ${s.tr('الإعدادات', 'Settings')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _section('📍 ${s.tr('الموقع', 'Location')}', [
          Autocomplete<String>(
            initialValue: TextEditingValue(text: s.cityAr),
            optionsBuilder: (v) {
              if (v.text.isEmpty) return popularCities.map((c) => c.ar);
              return popularCities.where((c) => c.ar.contains(v.text)).map((c) => c.ar);
            },
            onSelected: (v) {
              CityEntry? found;
              for (final c in popularCities) {
                if (c.ar == v.trim()) found = c;
              }
              if (found != null) {
                final f = found;
                s.update((x) {
                  x.cityAr = f.ar; x.city = f.city; x.country = f.country; x.countryAr = f.countryAr; x.useCoords = false;
                });
              } else {
                s.update((x) => x.cityAr = v);
              }
              setState(() {});
            },
            fieldViewBuilder: (ctx, ctrl, focus, done) => TextField(
              controller: ctrl,
              focusNode: focus,
              decoration: InputDecoration(hintText: s.tr('المدينة', 'City'), border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          Text('💡 ${s.tr('اختر مدينتك من القائمة لتتحدث المواقيت الرسمية تلقائياً', 'Pick your city — official times update automatically')}',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        _section('🕌 ${s.tr('طريقة الحساب والمذهب', 'Calculation & madhab')}', [
          DropdownButtonFormField<int>(
            // ignore: deprecated_member_use
            value: s.method,
            decoration: const InputDecoration(border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: [for (final m in calcMethods) DropdownMenuItem(value: m.id, child: Text(s.tr(m.ar, m.en), style: const TextStyle(fontSize: 13)))],
            onChanged: (v) {
              if (v != null) s.update((x) => x.method = v);
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final o in [(0, s.tr('شافعي (الجمهور)', 'Shafi')), (1, s.tr('حنفي', 'Hanafi'))])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        s.update((x) => x.madhab = o.$1);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: s.madhab == o.$1 ? const Color(0xFF047857) : Colors.grey.withValues(alpha: 0.2),
                        foregroundColor: s.madhab == o.$1 ? Colors.white : Colors.black87,
                      ),
                      child: Text(o.$2, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
            ],
          ),
        ]),
        _section('🕰️ ${s.tr('تعديل المواقيت يدوياً', 'Adjust times manually')}', [
          for (final p in prayers)
            Builder(builder: (_) {
              final custom = s.customTimes[p.key] ?? '';
              final isCustom = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(custom);
              final auto = widget.autoTimes?[p.key] ?? '--:--';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCustom ? const Color(0xFFFEF3C7) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${p.icon} ${s.tr(p.ar, p.en)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${s.tr('تلقائي', 'Auto')}: $auto${isCustom ? ' • ${s.tr('معدّل يدوياً', 'manual')}' : ''}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickTime(isCustom ? custom : auto == '--:--' ? '05:00' : auto,
                          (v) => s.update((x) => x.customTimes[p.key] = v)),
                      child: Text(isCustom ? custom : s.tr('تحديد وقت', 'Set time'),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (isCustom)
                      IconButton(
                        icon: const Text('↺'),
                        onPressed: () => s.update((x) => x.customTimes[p.key] = ''),
                      ),
                  ],
                ),
              );
            }),
          TextButton(
            onPressed: () => s.update((x) => x.customTimes = {'Fajr': '', 'Dhuhr': '', 'Asr': '', 'Maghrib': '', 'Isha': ''}),
            child: Text('↺ ${s.tr('تلقائي للكل', 'Auto for all')}'),
          ),
        ]),
        _section('🔊 ${s.tr('صوت الأذان عند دخول الوقت', 'Adhan at prayer time')}', [
          _toggleRow(s.tr('تشغيل الأذان', 'Play adhan'), s.adhanEnabled, (v) => s.update((x) => x.adhanEnabled = v)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (final a in adhanSounds.where((e) => e.id != 'custom'))
                ChoiceChip(
                  label: Text(s.tr(a.ar, a.en), style: const TextStyle(fontSize: 12)),
                  selected: s.adhanSound == a.id,
                  selectedColor: const Color(0xFF047857),
                  labelStyle: TextStyle(color: s.adhanSound == a.id ? Colors.white : null),
                  onSelected: (_) {
                    s.update((x) => x.adhanSound = a.id);
                    setState(() {});
                  },
                ),
              ChoiceChip(
                label: Text(s.tr('رابط مخصص', 'Custom'), style: const TextStyle(fontSize: 12)),
                selected: s.adhanSound == 'custom',
                selectedColor: const Color(0xFF047857),
                labelStyle: TextStyle(color: s.adhanSound == 'custom' ? Colors.white : null),
                onSelected: (_) {
                  s.update((x) => x.adhanSound = 'custom');
                  setState(() {});
                },
              ),
            ],
          ),
          if (s.adhanSound == 'custom') ...[
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: s.adhanCustomUrl),
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(hintText: 'https://...mp3', border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              onSubmitted: (v) => s.update((x) => x.adhanCustomUrl = v),
            ),
          ],
          Row(
            children: [
              Text('${s.tr('مستوى الصوت', 'Volume')}: ${(s.adhanVolume * 100).round()}%'),
              Expanded(
                child: Slider(
                  value: s.adhanVolume, min: 0, max: 1, divisions: 20,
                  onChanged: (v) {
                    s.update((x) => x.adhanVolume = v);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (testingAdhan) {
                  await _player.stop();
                  setState(() => testingAdhan = false);
                } else {
                  final url = getAdhanUrl(s.adhanSound, s.adhanCustomUrl);
                  if (url.isEmpty) return;
                  setState(() => testingAdhan = true);
                  try {
                    await _player.stop();
                    await _player.setVolume(s.adhanVolume);
                    await _player.play(UrlSource(url));
                  } catch (_) {
                    setState(() => testingAdhan = false);
                  }
                  _player.onPlayerComplete.listen((_) => mounted ? setState(() => testingAdhan = false) : null);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white),
              child: Text(testingAdhan ? '⏹️ ${s.tr('إيقاف التجربة', 'Stop preview')}' : '▶️ ${s.tr('تجربة صوت الأذان', 'Preview adhan')}'),
            ),
          ),
        ]),
        _section('🔔 ${s.tr('التنبيهات', 'Notifications')}', [
          _toggleRow(s.tr('تذكيرات الأذكار', 'Adhkar reminders'), s.adhkarReminders, (v) {
            s.update((x) => x.adhkarReminders = v);
            notify.scheduleDay(widget.autoTimes ?? fallbackTimings(), s);
          }),
          _toggleRow(s.tr('الصوت', 'Sound'), s.sound, (v) => s.update((x) => x.sound = v)),
          _toggleRow(s.tr('الاهتزاز', 'Vibration'), s.vibration, (v) => s.update((x) => x.vibration = v)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final r in [
                {'k': 'morning', 'label': '☀️ ${s.tr('الصباح', 'Morning')}', 'v': s.morningReminder},
                {'k': 'evening', 'label': '🌇 ${s.tr('المساء', 'Evening')}', 'v': s.eveningReminder},
                {'k': 'night', 'label': '🌙 ${s.tr('النوم', 'Night')}', 'v': s.nightReminder},
              ])
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(r['v']!, (v) {
                      s.update((x) {
                        if (r['k'] == 'morning') x.morningReminder = v;
                        if (r['k'] == 'evening') x.eveningReminder = v;
                        if (r['k'] == 'night') x.nightReminder = v;
                      });
                      notify.scheduleDay(widget.autoTimes ?? fallbackTimings(), s);
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Text(r['label']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(r['v']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ]),
        _section('🎨 ${s.tr('المظهر واللغة', 'Appearance & language')}', [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    s.update((x) => x.theme = 'light');
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: s.theme == 'light' ? const Color(0xFFFBBF24) : Colors.grey.withValues(alpha: 0.2),
                    foregroundColor: s.theme == 'light' ? Colors.black87 : null,
                  ),
                  child: Text('☀️ ${s.tr('فاتح', 'Light')}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    s.update((x) => x.theme = 'dark');
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: s.theme == 'dark' ? const Color(0xFF0F172A) : Colors.grey.withValues(alpha: 0.2),
                    foregroundColor: s.theme == 'dark' ? Colors.white : null,
                  ),
                  child: Text('🌙 ${s.tr('داكن', 'Dark')}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    s.update((x) => x.lang = 'ar');
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: s.lang == 'ar' ? const Color(0xFF047857) : Colors.grey.withValues(alpha: 0.2),
                    foregroundColor: s.lang == 'ar' ? Colors.white : null,
                  ),
                  child: const Text('العربية'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    s.update((x) => x.lang = 'en');
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: s.lang == 'en' ? const Color(0xFF047857) : Colors.grey.withValues(alpha: 0.2),
                    foregroundColor: s.lang == 'en' ? Colors.white : null,
                  ),
                  child: const Text('English'),
                ),
              ),
            ],
          ),
        ]),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              s.reset();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFEF2F2), foregroundColor: Colors.red),
            child: Text('🗑️ ${s.tr('إعادة تعيين كل الإعدادات', 'Reset all settings')}'),
          ),
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('صلاتي وذكري 🕌 • v2.0', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ),
        const SizedBox(height: 70),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, void Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF047857),
          onChanged: (v) {
            onChanged(v);
            setState(() {});
          },
        ),
      ],
    );
  }
}
