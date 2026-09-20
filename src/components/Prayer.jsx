import { useEffect, useState } from 'react';
import { PRAYERS, countdownTo, getNextPrayer, fetchMonthly, METHODS } from '../lib/api';
import { POPULAR_CITIES, findCity } from '../data/cities';

const t = (lang, ar, en) => (lang === 'ar' ? ar : en);

export default function Prayer({ settings, timings, hijri, onRefresh, loading, update }) {
  const [now, setNow] = useState(new Date());
  const [month, setMonth] = useState(null);
  const [monthLoading, setMonthLoading] = useState(false);
  const [showMonth, setShowMonth] = useState(false);

  useEffect(() => {
    const i = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(i);
  }, []);

  const next = timings ? getNextPrayer(timings, now) : null;

  const loadMonth = async () => {
    if (month) { setShowMonth(!showMonth); return; }
    setMonthLoading(true);
    try {
      const m = await fetchMonthly(settings);
      setMonth(m); // الجدول الشهري دائماً تلقائي من الحساب الفلكي
      setShowMonth(true);
    } catch { alert(lang === 'ar' ? 'تعذّر تحميل الجدول الشهري' : 'Failed to load monthly table'); }
    setMonthLoading(false);
  };

  const toggleNotif = (key) => {
    update({ prayerNotifs: { ...settings.prayerNotifs, [key]: !settings.prayerNotifs[key] } });
  };

  return (
    <div className="space-y-4 anim-fadeUp">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-extrabold">🕌 {t(settings.lang, 'مواقيت الصلاة', 'Prayer times')}</h2>
        <button onClick={onRefresh} className="text-sm bg-emerald-600 text-white px-3 py-2 rounded-xl font-bold active:scale-95 transition">
          {loading ? '⏳...' : `🔄 ${t(settings.lang, 'تحديث', 'Refresh')}`}
        </button>
      </div>

      <p className="text-sm text-slate-500 dark:text-slate-400">📍 {settings.cityAr} — {settings.countryAr} • {t(settings.lang, 'طريقة الحساب', 'Method')}: {METHODS.find((m) => m.id === settings.method)?.[settings.lang === 'ar' ? 'ar' : 'en']} • {t(settings.lang, 'العصر', 'Asr')}: {settings.madhab === 1 ? t(settings.lang, 'حنفي', 'Hanafi') : t(settings.lang, 'شافعي', 'Shafi')}</p>

      {/* change city / country — official times update automatically */}
      <div className="rounded-2xl bg-white dark:bg-slate-800 border border-emerald-200 dark:border-slate-700 p-4 shadow-soft">
        <p className="font-extrabold text-sm mb-2">📍 {t(settings.lang, 'غيّر مدينتك — تتحدث المواقيت تلقائياً', 'Change your city — times update automatically')}</p>
        <div className="grid grid-cols-2 gap-2">
          <input
            value={settings.cityAr} list="popular-cities"
            onChange={(e) => {
              const f = findCity(e.target.value);
              if (f) update({ cityAr: f.ar, city: f.city, country: f.country, countryAr: f.countryAr, useCoords: false });
              else update({ cityAr: e.target.value });
            }}
            placeholder={t(settings.lang, 'المدينة (مثال: الجزائر العاصمة)', 'City')}
            className="rounded-xl border p-2.5 text-sm bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 outline-none focus:border-emerald-500"
          />
          <datalist id="popular-cities">
            {POPULAR_CITIES.map((c) => <option key={c.ar} value={c.ar}>{c.countryAr}</option>)}
          </datalist>
          <input
            value={settings.countryAr}
            onChange={(e) => update({ countryAr: e.target.value })}
            placeholder={t(settings.lang, 'الدولة', 'Country')}
            className="rounded-xl border p-2.5 text-sm bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 outline-none focus:border-emerald-500"
          />
        </div>
        <div className="flex gap-2 mt-2">
          <button onClick={() => {
            if (!('geolocation' in navigator)) return;
            navigator.geolocation.getCurrentPosition(
              (pos) => update({ lat: +pos.coords.latitude.toFixed(4), lng: +pos.coords.longitude.toFixed(4), useCoords: true }),
              () => {}, { enableHighAccuracy: true }
            );
          }} className="flex-1 rounded-xl bg-sky-600 text-white font-bold py-2 text-xs active:scale-95 transition">🎯 GPS — {t(settings.lang, 'موقعي الحالي', 'My location')}</button>
          {settings.useCoords && <span className="text-[11px] font-bold text-emerald-600 self-center">✅ GPS {t(settings.lang, 'مفعّل', 'on')}</span>}
        </div>
      </div>

      {/* next countdown banner */}
      {timings && next && (
        <div className="rounded-3xl bg-gradient-to-l from-emerald-600 to-teal-600 text-white p-5 text-center shadow-soft">
          <p className="text-sm opacity-90">{t(settings.lang, 'الصلاة القادمة', 'Next prayer')}</p>
          <p className="text-3xl font-extrabold mt-1">{next.icon} {t(settings.lang, next.ar, next.en)} <span className="tabular-nums">{timings[next.key]}</span></p>
          <p className="text-2xl font-extrabold tabular-nums mt-2 bg-black/20 rounded-2xl py-2">⏳ {countdownTo(timings[next.key], now)}</p>
        </div>
      )}

      {/* five prayers with per-prayer notif toggle */}
      <div className="space-y-2">
        {timings && PRAYERS.map((p) => (
          <div key={p.key} className={`flex items-center justify-between rounded-2xl p-4 border shadow-soft ${next?.key === p.key ? 'bg-emerald-50 dark:bg-emerald-950/50 border-emerald-400' : 'bg-white dark:bg-slate-800 border-slate-100 dark:border-slate-700'}`}>
            <div className="flex items-center gap-3">
              <span className="text-3xl">{p.icon}</span>
              <div>
                <p className="font-extrabold">{t(settings.lang, p.ar, p.en)}</p>
                <p className="text-lg font-bold tabular-nums text-slate-600 dark:text-slate-200">{timings[p.key]}</p>
              </div>
              {next?.key === p.key && <span className="text-xs bg-emerald-600 text-white px-2 py-1 rounded-full font-bold">{t(settings.lang, 'القادمة', 'Next')}</span>}
            </div>
            <button
              onClick={() => toggleNotif(p.key)}
              title={t(settings.lang, 'تنبيه', 'Notify')}
              className={`text-2xl px-3 py-2 rounded-2xl active:scale-90 transition ${settings.prayerNotifs[p.key] ? 'bg-amber-100 dark:bg-amber-900/40' : 'bg-slate-100 dark:bg-slate-700 opacity-50'}`}
            >
              {settings.prayerNotifs[p.key] ? '🔔' : '🔕'}
            </button>
          </div>
        ))}
      </div>

      {/* monthly timetable */}
      <button onClick={loadMonth} className="w-full rounded-2xl bg-slate-900 dark:bg-amber-500 dark:text-slate-900 text-white font-extrabold p-4 active:scale-[.99] transition">
        {monthLoading ? '⏳ ' + t(settings.lang, 'جارٍ التحميل...', 'Loading...') : `📅 ${t(settings.lang, 'الجدول الشهري للمواقيت', 'Monthly timetable')}`}
      </button>
      {showMonth && month && (
        <div className="rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-700 shadow-soft">
          <div className="overflow-x-auto max-h-96 overflow-y-auto">
            <table className="w-full text-xs text-center">
              <thead className="bg-emerald-600 text-white sticky top-0">
                <tr>
                  <th className="p-2">{t(settings.lang, 'اليوم', 'Day')}</th>
                  {PRAYERS.map((p) => <th key={p.key} className="p-2">{t(settings.lang, p.ar, p.en)}</th>)}
                </tr>
              </thead>
              <tbody>
                {month.map((d, i) => (
                  <tr key={i} className={i % 2 ? 'bg-slate-50 dark:bg-slate-800' : 'bg-white dark:bg-slate-900'}>
                    <td className="p-2 font-bold">{d.day}</td>
                    {PRAYERS.map((p) => <td key={p.key} className="p-2 tabular-nums">{d.timings[p.key]}</td>)}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <div className="rounded-2xl bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/40 p-4 text-sm leading-7">
        <p className="font-extrabold">💡 {t(settings.lang, 'ملاحظة', 'Note')}</p>
        <p className="text-slate-600 dark:text-slate-300">{t(settings.lang, 'اضغط على 🔔 بجانب كل صلاة لتفعيل التنبيه أو كتمه. يتم إرسال إشعار مثل: «حان وقت الصلاة: صلاة العصر». لتعديل وقت صلاة بدقة اذهب للإعدادات ← تعديل المواقيت يدوياً. الجدول الشهري يعرض الأوقات الفلكية التلقائية.', 'Tap 🔔 next to each prayer to enable/mute its alert. To set an exact time for a prayer go to Settings. The monthly table shows automatic astronomical times.')}</p>
      </div>
    </div>
  );
}
