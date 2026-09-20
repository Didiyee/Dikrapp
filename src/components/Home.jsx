import { useEffect, useState } from 'react';
import { PRAYERS, countdownTo, getNextPrayer, getCurrentPrayer, formatHijri, formatGregorian } from '../lib/api';
import { getDailyAyah, CATEGORIES, ADHKAR } from '../data/adhkar';

const t = (lang, ar, en) => (lang === 'ar' ? ar : en);

export default function Home({ settings, timings, hijri, go }) {
  const [now, setNow] = useState(new Date());
  useEffect(() => {
    const i = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(i);
  }, []);
  const lang = settings.lang;
  const next = timings ? getNextPrayer(timings, now) : null;
  const cur = timings ? getCurrentPrayer(timings, now) : null;
  const ayah = getDailyAyah();
  const hour = now.getHours();
  const greet = lang === 'ar'
    ? hour < 12 ? '🌅 صباح الخير — السلام عليكم' : hour < 18 ? '☀️ مساء النور — السلام عليكم' : '🌙 مساء الخير — السلام عليكم'
    : hour < 12 ? 'Good morning — As-salamu alaikum' : 'Good evening — As-salamu alaikum';

  // time-based adhkar suggestion
  let suggest = null;
  if (timings) {
    const mins = (s) => { const [h, m] = s.split(':').map(Number); return h * 60 + m; };
    const curM = now.getHours() * 60 + now.getMinutes();
    if (curM >= mins(timings.Fajr) && curM < mins(timings.Dhuhr)) suggest = 'morning';
    else if (curM >= mins(timings.Asr)) suggest = 'evening';
    else if (curM >= 21 * 60 || curM < mins(timings.Fajr)) suggest = 'sleep';
    else suggest = 'afterPrayer';
  }
  const suggestCat = CATEGORIES.find((c) => c.id === suggest);
  const favCount = settings.favorites.length;
  const notesCount = settings.notes.length;

  const quick = [
    { label: t(lang, 'مواقيت الصلاة', 'Prayer times'), icon: '🕌', to: 'prayer', color: 'from-emerald-500 to-teal-600' },
    { label: t(lang, 'أذكار الصباح', 'Morning'), icon: '🌅', to: 'adhkar:morning', color: 'from-amber-400 to-orange-500' },
    { label: t(lang, 'أذكار المساء', 'Evening'), icon: '🌇', to: 'adhkar:evening', color: 'from-sky-500 to-indigo-600' },
    { label: t(lang, 'أذكار بعد الصلاة', 'After prayer'), icon: '🤲', to: 'adhkar:afterPrayer', color: 'from-violet-500 to-purple-600' },
    { label: t(lang, 'القرآن الكريم', 'Quran'), icon: '📖', to: 'quran', color: 'from-emerald-500 to-green-600' },
    { label: t(lang, 'اتجاه القبلة', 'Qibla'), icon: '🧭', to: 'qibla', color: 'from-rose-500 to-red-600' },
  ];

  return (
    <div className="space-y-4 anim-fadeUp">
      {/* greeting */}
      <div className="rounded-3xl bg-gradient-to-l from-emerald-600 via-teal-600 to-emerald-700 text-white p-5 shadow-soft relative overflow-hidden">
        <div className="absolute inset-0 pattern-bg opacity-60" />
        <div className="relative">
          <p className="text-lg font-bold">{greet}</p>
          <p className="text-emerald-50/90 text-sm mt-1">{formatGregorian(null, lang)}</p>
          <p className="text-amber-200 text-sm font-semibold">🗓️ {formatHijri(hijri, lang)}</p>
          <p className="text-xs mt-1 text-emerald-100">📍 {settings.cityAr} — {settings.countryAr}</p>
        </div>
      </div>

      {/* current / next prayer */}
      {timings && next && cur && (
        <div className="grid grid-cols-2 gap-3">
          <div className="rounded-2xl bg-white dark:bg-slate-800 p-4 shadow-soft border border-emerald-100 dark:border-slate-700 text-center">
            <p className="text-xs text-slate-500 dark:text-slate-400">{t(lang, 'الصلاة الحالية', 'Current')}</p>
            <p className="text-2xl my-1">{cur.icon}</p>
            <p className="font-extrabold text-emerald-700 dark:text-emerald-300">{t(lang, cur.ar, cur.en)}</p>
            <p className="text-sm font-bold mt-1 tabular-nums">{timings[cur.key]}</p>
          </div>
          <div className="rounded-2xl bg-gradient-to-b from-amber-50 to-amber-100 dark:from-slate-800 dark:to-slate-800 p-4 shadow-soft border border-amber-200 dark:border-amber-900/40 text-center">
            <p className="text-xs text-slate-500 dark:text-slate-400">{t(lang, 'الصلاة القادمة', 'Next prayer')}</p>
            <p className="text-2xl my-1 anim-pulse-soft">{next.icon}</p>
            <p className="font-extrabold text-amber-700 dark:text-amber-300">{t(lang, next.ar, next.en)} — {timings[next.key]}</p>
            <p className="text-lg font-extrabold tabular-nums text-slate-800 dark:text-white mt-1">⏳ {countdownTo(timings[next.key], now)}</p>
          </div>
        </div>
      )}

      {/* prayer strip */}
      {timings && (
        <div className="rounded-2xl bg-white dark:bg-slate-800 p-3 shadow-soft border border-slate-100 dark:border-slate-700">
          <div className="flex justify-between overflow-x-auto gap-2">
            {PRAYERS.map((p) => (
              <div key={p.key} className={`min-w-[60px] flex-1 text-center rounded-xl py-2 px-1 ${next?.key === p.key ? 'bg-emerald-600 text-white font-bold' : 'bg-slate-50 dark:bg-slate-700/60'}`}>
                <div className="text-lg">{p.icon}</div>
                <div className="text-xs font-bold">{t(lang, p.ar, p.en)}</div>
                <div className="text-xs tabular-nums opacity-90">{timings[p.key]}</div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* quick access */}
      <div>
        <h3 className="font-extrabold mb-2 text-slate-700 dark:text-slate-200">⚡ {t(lang, 'وصول سريع', 'Quick access')}</h3>
        <div className="grid grid-cols-3 sm:grid-cols-6 gap-2">
          {quick.map((q) => (
            <button key={q.to} onClick={() => go(q.to)} className={`rounded-2xl bg-gradient-to-b ${q.color} text-white p-3 shadow-soft active:scale-95 transition`}>
              <div className="text-2xl">{q.icon}</div>
              <div className="text-xs font-bold mt-1 leading-tight">{q.label}</div>
            </button>
          ))}
        </div>
      </div>

      {/* time-based suggestion */}
      {suggestCat && (
        <button onClick={() => go(`adhkar:${suggestCat.id}`)} className="w-full text-right rounded-2xl border-2 border-dashed border-emerald-400 bg-emerald-50 dark:bg-emerald-950/40 p-4 flex items-center gap-3 active:scale-[.99] transition">
          <span className="text-3xl">{suggestCat.icon}</span>
          <span>
            <span className="block font-extrabold text-emerald-800 dark:text-emerald-200">🔔 {t(lang, 'حان وقت', 'Time for')} {t(lang, suggestCat.ar, suggestCat.en)}</span>
            <span className="block text-xs text-slate-500 dark:text-slate-400">{t(lang, 'اضغط لبدء الذكر الآن — لا تنسَ أذكارك', 'Tap to start now')}</span>
          </span>
        </button>
      )}

      {/* daily ayah */}
      <div className="rounded-3xl bg-gradient-to-l from-slate-900 via-emerald-900 to-slate-900 text-white p-5 shadow-soft text-center relative overflow-hidden">
        <div className="absolute inset-0 pattern-bg" />
        <p className="text-xs text-amber-300 font-bold relative">✨ {t(lang, 'آية اليوم', "Today's verse")}</p>
        <p className="font-quran text-xl leading-[2.2] mt-2 relative">{ayah.text}</p>
        <p className="text-amber-200/90 text-xs mt-2 relative">{ayah.ref}</p>
      </div>

      {/* bookmarks / notes summary — دفتر المحفوظات */}
      <div className="grid grid-cols-2 gap-3">
        <button onClick={() => go('adhkar:fav')} className="rounded-2xl bg-white dark:bg-slate-800 border border-amber-200 dark:border-slate-700 p-4 text-center shadow-soft active:scale-95 transition">
          <div className="text-2xl">⭐</div>
          <div className="font-extrabold text-sm mt-1">{t(lang, 'المفضلة (Bookmarks)', 'Bookmarks')}</div>
          <div className="text-xs text-slate-500">{favCount} {t(lang, 'ذكر محفوظ', 'saved')}</div>
        </button>
        <button onClick={() => go('adhkar:notes')} className="rounded-2xl bg-white dark:bg-slate-800 border border-sky-200 dark:border-slate-700 p-4 text-center shadow-soft active:scale-95 transition">
          <div className="text-2xl">📝</div>
          <div className="font-extrabold text-sm mt-1">{t(lang, 'دفتر الملاحظات (Booknotes)', 'Booknotes')}</div>
          <div className="text-xs text-slate-500">{notesCount} {t(lang, 'ملاحظة', 'notes')}</div>
        </button>
      </div>
    </div>
  );
}
