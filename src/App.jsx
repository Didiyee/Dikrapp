import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSettings } from './lib/store';
import { fetchTimings, fallbackTimings, PRAYERS, applyCustomTimes } from './lib/api';
import { ensurePermission, notify } from './lib/notify';
import { playAdhan, unlockAdhanAudio } from './lib/adhan';
import Home from './components/Home';
import Prayer from './components/Prayer';
import Adhkar from './components/Adhkar';
import Quran from './components/Quran';
import Qibla from './components/Qibla';
import Settings from './components/Settings';

export default function App() {
  const [settings, update, setSettings, reset] = useSettings();
  const [tab, setTab] = useState('home'); // home|prayer|adhkar|qibla|settings
  const [adhkarCat, setAdhkarCat] = useState('morning');
  const [timings, setTimings] = useState(null);
  const [hijri, setHijri] = useState(null);
  const [loading, setLoading] = useState(false);
  const lang = settings.lang;

  // المواقيت بعد التعديل اليدوي من المستخدم
  const adjustedTimings = useMemo(
    () => applyCustomTimes(timings, settings.customTimes),
    [timings, settings.customTimes]
  );

  const go = (to) => {
    if (to.startsWith('adhkar')) {
      const [, cat] = to.split(':');
      if (cat) setAdhkarCat(cat);
      setTab('adhkar');
    } else setTab(to);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const r = await fetchTimings(settings);
      setTimings(r.timings);
      setHijri(r.hijri);
    } catch {
      setTimings(fallbackTimings());
    }
    setLoading(false);
  }, [settings.city, settings.country, settings.method, settings.madhab, settings.useCoords, settings.lat, settings.lng]);

  useEffect(() => { load(); }, [load]);

  // theme + lang + dir
  useEffect(() => {
    document.documentElement.classList.toggle('dark', settings.theme === 'dark');
    document.documentElement.lang = settings.lang;
    document.documentElement.dir = settings.lang === 'ar' ? 'rtl' : 'ltr';
  }, [settings.theme, settings.lang]);

  useEffect(() => { ensurePermission(); }, []);

  // فتح صوت الأذان عند أول لمسة (شرط المتصفحات للتشغيل التلقائي)
  useEffect(() => {
    const fn = () => unlockAdhanAudio();
    window.addEventListener('pointerdown', fn, { once: true });
    return () => window.removeEventListener('pointerdown', fn);
  }, []);

  // ── notification scheduler (every 20s) ──
  useEffect(() => {
    const fired = new Set();
    const id = setInterval(() => {
      const now = new Date();
      const hm = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
      const key = `${hm}-${now.getDate()}`;
      if (fired.has(key)) return;

      // prayer notifications + adhan
      if (adjustedTimings) {
        for (const p of PRAYERS) {
          if (adjustedTimings[p.key] === hm && settings.prayerNotifs[p.key]) {
            fired.add(key);
            if (settings.adhanEnabled) playAdhan(settings);
            notify(
              lang === 'ar' ? `🕌 حان وقت الصلاة: صلاة ${p.ar}` : `Prayer time: ${p.en}`,
              lang === 'ar' ? 'حي على الصلاة — تقبّل الله منا ومنكم' : 'Come to prayer',
              settings
            );
          }
        }
      }
      // adhkar reminders
      if (settings.adhkarReminders) {
        const map = {
          [settings.morningReminder]: lang === 'ar' ? '🌅 حان وقت أذكار الصباح' : 'Time for morning adhkar',
          [settings.eveningReminder]: lang === 'ar' ? '🌇 حان وقت أذكار المساء' : 'Time for evening adhkar',
          [settings.nightReminder]: lang === 'ar' ? '🌙 حان وقت أذكار النوم — لا تنسَ أذكارك' : "Time for sleep adhkar",
        };
        if (map[hm]) {
          fired.add(key);
          notify(map[hm], lang === 'ar' ? 'لا تنسَ أذكارك 🤲' : 'Do not forget your adhkar', settings);
        }
      }
    }, 20000);
    return () => clearInterval(id);
  }, [adjustedTimings, settings.prayerNotifs, settings.adhkarReminders, settings.morningReminder, settings.eveningReminder, settings.nightReminder, settings.sound, settings.vibration, settings.adhanEnabled, settings.adhanSound, settings.adhanCustomUrl, settings.adhanVolume, lang]);

  const nav = [
    { id: 'home', label: lang === 'ar' ? 'الرئيسية' : 'Home', icon: '🏠' },
    { id: 'prayer', label: lang === 'ar' ? 'الصلاة' : 'Prayer', icon: '🕌' },
    { id: 'adhkar', label: lang === 'ar' ? 'الأذكار' : 'Adhkar', icon: '📿' },
    { id: 'quran', label: lang === 'ar' ? 'القرآن' : 'Quran', icon: '📖' },
    { id: 'qibla', label: lang === 'ar' ? 'القبلة' : 'Qibla', icon: '🧭' },
    { id: 'settings', label: lang === 'ar' ? 'الإعدادات' : 'Settings', icon: '⚙️' },
  ];

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-800 dark:text-slate-100 transition-colors">
      {/* top bar */}
      <header className="sticky top-0 z-20 bg-gradient-to-l from-emerald-700 to-teal-700 text-white shadow-lg">
        <div className="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-2xl">🕌</span>
            <div>
              <h1 className="font-extrabold leading-none">صلاتي وذكري</h1>
              <p className="text-[11px] text-emerald-100">{lang === 'ar' ? 'مواقيت • أذكار • قبلة • دفتر' : 'Times • Adhkar • Qibla • Notes'}</p>
            </div>
          </div>
          <button onClick={() => update({ theme: settings.theme === 'dark' ? 'light' : 'dark' })} className="bg-white/15 rounded-xl px-3 py-2 active:scale-90 transition">{settings.theme === 'dark' ? '☀️' : '🌙'}</button>
        </div>
      </header>

      {/* content */}
      <main className="max-w-2xl mx-auto px-3 pt-4 pb-28 pattern-bg min-h-[70vh]">
        {tab === 'home' && <Home settings={settings} timings={adjustedTimings} hijri={hijri} go={go} />}
        {tab === 'prayer' && <Prayer settings={settings} timings={adjustedTimings} hijri={hijri} onRefresh={load} loading={loading} update={update} />}
        {tab === 'adhkar' && <Adhkar key={adhkarCat} settings={settings} setSettings={setSettings} initialCat={adhkarCat} />}
        {tab === 'quran' && <Quran lang={lang} riwaya={settings.quranRiwaya || 'hafs'} onRiwaya={(r) => update({ quranRiwaya: r })} />}
        {tab === 'qibla' && <Qibla settings={settings} update={update} />}
        {tab === 'settings' && <Settings settings={settings} update={update} reset={reset} autoTimes={timings} />}
      </main>

      {/* bottom nav */}
      <nav className="fixed bottom-0 inset-x-0 z-20 bg-white/95 dark:bg-slate-900/95 backdrop-blur border-t border-slate-200 dark:border-slate-700" style={{ paddingBottom: 'env(safe-area-inset-bottom)' }}>
        <div className="max-w-2xl mx-auto grid grid-cols-6">
          {nav.map((n) => (
            <button key={n.id} onClick={() => go(n.id)} className={`py-2.5 flex flex-col items-center gap-0.5 active:scale-95 transition ${tab === n.id ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-400'}`}>
              <span className={`text-2xl ${tab === n.id ? 'scale-110' : ''} transition`}>{n.icon}</span>
              <span className={`text-[11px] font-extrabold ${tab === n.id ? '' : 'font-normal'}`}>{n.label}</span>
              {tab === n.id && <span className="w-8 h-1 rounded-full bg-emerald-500" />}
            </button>
          ))}
        </div>
      </nav>
    </div>
  );
}
