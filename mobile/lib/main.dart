import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/settings.dart';
import 'core/prayer.dart';
import 'services/notify.dart' as notify;
import 'screens/home.dart';
import 'screens/prayer.dart';
import 'screens/adhkar.dart';
import 'screens/quran.dart';
import 'screens/qibla.dart';
import 'screens/settings.dart';

final AudioPlayer adhanPlayer = AudioPlayer();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  await notify.initNotifications();
  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final AppSettings settings;
  const MyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final ar = settings.isAr;
        final light = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF047857)),
          textTheme: GoogleFonts.tajawalTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF047857), foregroundColor: Colors.white, centerTitle: true,
          ),
        );
        final dark = ThemeData(
          useMaterial3: true, brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF047857), brightness: Brightness.dark),
          textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(centerTitle: true),
        );
        return MaterialApp(
          title: 'صلاتي وذكري',
          debugShowCheckedModeBanner: false,
          locale: Locale(ar ? 'ar' : 'en'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: light,
          darkTheme: dark,
          themeMode: settings.theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
          home: MainShell(settings: settings),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final AppSettings settings;
  const MainShell({super.key, required this.settings});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  String adhkarCat = 'morning';
  Map<String, String>? timings;
  Map<String, dynamic>? hijri;
  bool loading = false;
  Timer? _sec;
  String _firedKey = '';

  AppSettings get s => widget.settings;

  @override
  void initState() {
    super.initState();
    _load();
    _sec = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _sec?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final r = await fetchTimings(
        city: s.city, country: s.country, method: s.method, madhab: s.madhab,
        useCoords: s.useCoords, lat: s.lat, lng: s.lng,
      );
      if (!mounted) return;
      setState(() {
        timings = applyCustomTimes(r.timings, s.customTimes);
        hijri = r.hijri;
      });
      await notify.scheduleDay(timings!, s);
    } catch (_) {
      if (!mounted) return;
      setState(() => timings = applyCustomTimes(fallbackTimings(), s.customTimes));
    }
    if (mounted) setState(() => loading = false);
  }

  /// Foreground adhan at prayer time (works while the app is open).
  Future<void> _tick() async {
    if (timings == null) return;
    final now = DateTime.now();
    final hm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final key = '$hm-${now.day}';
    if (key == _firedKey) return;
    for (final p in prayers) {
      if (timings![p.key] == hm && (s.prayerNotifs[p.key] ?? false)) {
        _firedKey = key;
        if (s.adhanEnabled) {
          try {
            final url = getAdhanUrl(s.adhanSound, s.adhanCustomUrl);
            if (url.isNotEmpty) {
              await adhanPlayer.stop();
              await adhanPlayer.setVolume(s.adhanVolume);
              await adhanPlayer.play(UrlSource(url));
            }
          } catch (_) {}
        }
        setState(() {});
        return;
      }
    }
  }

  void go(String to) {
    if (to.startsWith('adhkar')) {
      final parts = to.split(':');
      if (parts.length > 1) adhkarCat = parts[1];
      setState(() => tab = 2);
    } else {
      const order = ['home', 'prayer', 'adhkar', 'quran', 'qibla', 'settings'];
      final i = order.indexOf(to);
      if (i >= 0) setState(() => tab = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      BottomNavigationBarItem(icon: const Text('🏠', style: TextStyle(fontSize: 22)), label: s.tr('الرئيسية', 'Home')),
      BottomNavigationBarItem(icon: const Text('🕌', style: TextStyle(fontSize: 22)), label: s.tr('الصلاة', 'Prayer')),
      BottomNavigationBarItem(icon: const Text('📿', style: TextStyle(fontSize: 22)), label: s.tr('الأذكار', 'Adhkar')),
      BottomNavigationBarItem(icon: const Text('📖', style: TextStyle(fontSize: 22)), label: s.tr('القرآن', 'Quran')),
      BottomNavigationBarItem(icon: const Text('🧭', style: TextStyle(fontSize: 22)), label: s.tr('القبلة', 'Qibla')),
      BottomNavigationBarItem(icon: const Text('⚙️', style: TextStyle(fontSize: 22)), label: s.tr('الإعدادات', 'Settings')),
    ];
    final pages = [
      HomeScreen(settings: s, timings: timings, hijri: hijri, go: go),
      PrayerScreen(settings: s, timings: timings, loading: loading, onRefresh: _load),
      AdhkarScreen(settings: s, initialCat: adhkarCat, key: ValueKey('adhkar-$adhkarCat-$tab')),
      QuranScreen(settings: s),
      QiblaScreen(settings: s),
      SettingsScreen(settings: s, autoTimes: timings),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('صلاتي وذكري', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(s.tr('مواقيت • أذكار • قبلة • قرآن', 'Times • Adhkar • Qibla • Quran'),
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: Text(s.theme == 'dark' ? '☀️' : '🌙', style: const TextStyle(fontSize: 20)),
            onPressed: () => s.update((x) => x.theme = x.theme == 'dark' ? 'light' : 'dark'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: s.theme == 'dark'
                ? [const Color(0xFF0F172A), const Color(0xFF022C22)]
                : [const Color(0xFFF8FAFC), const Color(0xFFECFDF5)],
          ),
        ),
        child: pages[tab],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: (i) => setState(() => tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF047857),
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: items,
      ),
    );
  }
}
