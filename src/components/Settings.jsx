import { METHODS, PRAYERS, ADHAN_SOUNDS } from '../lib/api';
import { POPULAR_CITIES, findCity } from '../data/cities';
import { ensurePermission } from '../lib/notify';
import { playAdhan, stopAdhan } from '../lib/adhan';
import { useState } from 'react';

const t = (lang, ar, en) => (lang === 'ar' ? ar : en);

function Row({ label, children }) {
  return (
    <div className="flex items-center justify-between gap-3 py-3 border-b border-slate-100 dark:border-slate-700/60 last:border-0">
      <span className="text-sm font-bold">{label}</span>
      <span className="flex items-center gap-2">{children}</span>
    </div>
  );
}

function Toggle({ on, onClick }) {
  return (
    <button onClick={onClick} className={`w-12 h-7 rounded-full transition relative ${on ? 'bg-emerald-500' : 'bg-slate-300 dark:bg-slate-600'}`}>
      <span className={`absolute top-1 w-5 h-5 rounded-full bg-white shadow transition-all ${on ? 'right-1' : 'left-1'}`} />
    </button>
  );
}

export default function Settings({ settings, update, reset, autoTimes }) {
  const lang = settings.lang;
  const [testingAdhan, setTestingAdhan] = useState(false);

  const setTheme = (theme) => {
    update({ theme });
    document.documentElement.classList.toggle('dark', theme === 'dark');
  };
  const setLang = (l) => {
    update({ lang: l });
    document.documentElement.lang = l;
    document.documentElement.dir = l === 'ar' ? 'rtl' : 'ltr';
  };

  return (
    <div className="space-y-4 anim-fadeUp">
      <h2 className="text-xl font-extrabold">⚙️ {t(lang, 'الإعدادات', 'Settings')}</h2>

      {/* location */}
      <div className="rounded-2xl bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 p-4 shadow-soft">
        <p className="font-extrabold mb-1">📍 {t(lang, 'الموقع', 'Location')}</p>
        <div className="grid grid-cols-2 gap-2">
          <input value={settings.cityAr} list="popular-cities-settings" onChange={(e) => {
            const f = findCity(e.target.value);
            if (f) update({ cityAr: f.ar, city: f.city, country: f.country, countryAr: f.countryAr, useCoords: false });
            else update({ cityAr: e.target.value });
          }} placeholder="المدينة بالعربية" className="rounded-xl border p-2.5 text-sm bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 outline-none focus:border-emerald-500" />
          <datalist id="popular-cities-settings">
            {POPULAR_CITIES.map((c) => <option key={c.ar} value={c.ar}>{c.countryAr}</option>)}
          </datalist>
          <input value={settings.city} onChange={(e) => update({ city: e.target.value })} placeholder="City (English)" className="rounded-xl border p-2.5 text-sm bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 outline-none focus:border-emerald-500" dir="ltr" />
          <input value={settings.countryAr} onChange={(e) => update({ countryAr: e.target.value })} placeholder="الدولة بالعربية" className="rounded-xl border p-2.5 text-sm bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 outline-none focus:border-emerald-500" />
          <input value={settings.country} onChange={(e) => update({ country: e.target.value })} placeholder="Country (English)" className="rounded-xl border p-2.5 text-sm bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 outline-none focus:border-emerald-500" dir="ltr" />
        </div>
        <p className="text-[11px] text-slate-400 mt-1">💡 {t(lang, 'اكتب المدينة والدولة بالإنجليزية أيضاً لدقة جلب المواقيت (مثال: Makkah / Saudi Arabia)', 'Also write city/country in English for accuracy (e.g. Makkah / Saudi Arabia)')}</p>
      </div>

      {/* calculation */}
      <div className="rounded-2xl bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 p-4 shadow-soft">
        <p className="font-extrabold mb-2">🕌 {t(lang, 'طريقة الحساب والمذهب', 'Calculation & madhab')}</p>
        <select value={settings.method} onChange={(e) => update({ method: Number(e.target.value) })} className="w-full rounded-xl border p-2.5 text-sm bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700">
          {METHODS.map((m) => <option key={m.id} value={m.id}>{lang === 'ar' ? m.ar : m.en}</option>)}
        </select>
        <div className="grid grid-cols-2 gap-2 mt-2">
          {[{ v: 0, l: t(lang, 'شافعي (الجمهور)', 'Shafi') }, { v: 1, l: t(lang, 'حنفي', 'Hanafi') }].map((o) => (
            <button key={o.v} onClick={() => update({ madhab: o.v })} className={`rounded-xl py-2.5 text-sm font-bold border active:scale-95 transition ${settings.madhab === o.v ? 'bg-emerald-600 text-white border-emerald-600' : 'border-slate-200 dark:border-slate-700'}`}>{o.l}</button>
          ))}
        </div>
      </div>

      {/* manual prayer-time adjustment — exact times */}
      <div className="rounded-2xl bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 p-4 shadow-soft">
        <div className="flex items-center justify-between mb-1">
          <p className="font-extrabold">🕰️ {t(lang, 'تعديل المواقيت يدوياً', 'Adjust times manually')}</p>
          <button onClick={() => update({ customTimes: { Fajr: '', Dhuhr: '', Asr: '', Maghrib: '', Isha: '' } })} className="text-xs bg-slate-100 dark:bg-slate-700 px-3 py-1.5 rounded-full font-bold">↺ {t(lang, 'تلقائي للكل', 'Auto for all')}</button>
        </div>
        {PRAYERS.map((p) => {
          const custom = settings.customTimes?.[p.key] || '';
          const auto = autoTimes?.[p.key] || '--:--';
          const isCustom = /^([01]\d|2[0-3]):[0-5]\d$/.test(custom);
          return (
            <div key={p.key} className={`flex items-center justify-between gap-2 py-2.5 border-b border-slate-100 dark:border-slate-700/60 last:border-0 rounded-xl px-2 ${isCustom ? 'bg-amber-50 dark:bg-amber-950/30' : ''}`}>
              <span className="text-sm font-bold flex-1">{p.icon} {t(lang, p.ar, p.en)}
                <span className="block text-[11px] font-normal text-slate-400">{t(lang, 'تلقائي', 'Auto')}: <span className="tabular-nums">{auto}</span>{isCustom && <span className="text-amber-600 font-bold"> • {t(lang, 'معدّل يدوياً', 'manual')}</span>}</span>
              </span>
              <input
                type="time"
                value={custom}
                onChange={(e) => update({ customTimes: { ...settings.customTimes, [p.key]: e.target.value } })}
                className="rounded-xl border border-slate-200 dark:border-slate-600 bg-slate-50 dark:bg-slate-900 p-2 text-sm tabular-nums outline-none focus:border-emerald-500"
              />
              {isCustom && <button onClick={() => update({ customTimes: { ...settings.customTimes, [p.key]: '' } })} title={t(lang, 'رجوع للتلقائي', 'Back to auto')} className="text-lg px-1 active:scale-90">↺</button>}
            </div>
          );
        })}
        <p className="text-[11px] text-slate-400 mt-1">💡 {t(lang, 'اترك الحقل فارغاً ليبقى الوقت تلقائياً. أي وقت تكتبه يُستخدم فوراً في الشاشات والعد التنازلي والأذان والتنبيهات.', 'Leave empty to keep automatic time. Any time you set is used immediately in screens, countdown, adhan and alerts.')}</p>
      </div>

      {/* adhan */}
      <div className="rounded-2xl bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 p-4 shadow-soft">
        <p className="font-extrabold mb-1">🔊 {t(lang, 'صوت الأذان عند دخول الوقت', 'Adhan at prayer time')}</p>
        <Row label={t(lang, 'تشغيل الأذان', 'Play adhan')}><Toggle on={settings.adhanEnabled} onClick={() => update({ adhanEnabled: !settings.adhanEnabled })} /></Row>
        <div className="grid grid-cols-2 gap-2 mt-2">
          {ADHAN_SOUNDS.filter((s) => s.id !== 'custom').map((s) => (
            <button key={s.id} onClick={() => update({ adhanSound: s.id })} className={`rounded-xl py-2.5 px-2 text-xs font-bold border active:scale-95 transition ${settings.adhanSound === s.id ? 'bg-emerald-600 text-white border-emerald-600' : 'border-slate-200 dark:border-slate-700'}`}>🕌 {lang === 'ar' ? s.ar : s.en}</button>
          ))}
        </div>
        <button onClick={() => update({ adhanSound: 'custom' })} className={`mt-2 w-full rounded-xl py-2 text-xs font-bold border ${settings.adhanSound === 'custom' ? 'bg-emerald-600 text-white border-emerald-600' : 'border-slate-200 dark:border-slate-700'}`}>🔗 {t(lang, 'استخدام رابط mp3 مخصص', 'Use custom mp3 link')}</button>
        {settings.adhanSound === 'custom' && (
          <input value={settings.adhanCustomUrl} onChange={(e) => update({ adhanCustomUrl: e.target.value })} placeholder="https://...mp3" dir="ltr" className="mt-2 w-full rounded-xl border p-2.5 text-sm bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 outline-none focus:border-emerald-500" />
        )}
        <label className="block text-xs font-bold mt-3">{t(lang, 'مستوى الصوت', 'Volume')}: {Math.round((Number(settings.adhanVolume) || 0) * 100)}%
          <input type="range" min="0" max="1" step="0.05" value={settings.adhanVolume} onChange={(e) => update({ adhanVolume: Number(e.target.value) })} className="w-full mt-1" />
        </label>
        <button
          onClick={() => { if (testingAdhan) { stopAdhan(); setTestingAdhan(false); } else { setTestingAdhan(playAdhan(settings)); } }}
          className="mt-2 w-full rounded-xl bg-emerald-600 text-white font-extrabold py-2.5 active:scale-[.99] transition"
        >
          {testingAdhan ? `⏹️ ${t(lang, 'إيقاف التجربة', 'Stop preview')}` : `▶️ ${t(lang, 'تجربة صوت الأذان', 'Preview adhan')}`}
        </button>
        <p className="text-[11px] text-slate-400 mt-2">💡 {t(lang, 'يُشغَّل الأذان تلقائياً عند دخول كل صلاة مفعّلة 🔔. المس الشاشة مرة واحدة بعد فتح التطبيق حتى يسمح الهاتف بالتشغيل التلقائي.', 'Adhan plays automatically at each enabled prayer time. Tap the screen once after opening the app so the phone allows autoplay.')}</p>
      </div>

      {/* notifications */}
      <div className="rounded-2xl bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 p-4 shadow-soft">
        <div className="flex items-center justify-between mb-1">
          <p className="font-extrabold">🔔 {t(lang, 'التنبيهات', 'Notifications')}</p>
          <button onClick={async () => { await ensurePermission(); }} className="text-xs bg-amber-100 dark:bg-amber-900/40 text-amber-800 dark:text-amber-200 px-3 py-1.5 rounded-full font-bold">🔔 {t(lang, 'طلب الإذن', 'Allow')}</button>
        </div>
        <Row label={t(lang, 'تذكيرات الأذكار', 'Adhkar reminders')}><Toggle on={settings.adhkarReminders} onClick={() => update({ adhkarReminders: !settings.adhkarReminders })} /></Row>
        <Row label={t(lang, 'الصوت', 'Sound')}><Toggle on={settings.sound} onClick={() => update({ sound: !settings.sound })} /></Row>
        <Row label={t(lang, 'الاهتزاز', 'Vibration')}><Toggle on={settings.vibration} onClick={() => update({ vibration: !settings.vibration })} /></Row>
        <div className="grid grid-cols-3 gap-2 mt-2 text-center">
          {[
            { k: 'morningReminder', l: t(lang, '☀️ الصباح', 'Morning') },
            { k: 'eveningReminder', l: t(lang, '🌇 المساء', 'Evening') },
            { k: 'nightReminder', l: t(lang, '🌙 النوم', 'Night') },
          ].map((r) => (
            <label key={r.k} className="text-xs font-bold">{r.l}
              <input type="time" value={settings[r.k]} onChange={(e) => update({ [r.k]: e.target.value })} className="mt-1 w-full rounded-xl border p-2 bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 tabular-nums" />
            </label>
          ))}
        </div>
        <p className="text-[11px] text-slate-400 mt-2">🔔 {t(lang, 'رسائل مهذبة مثل: «حان وقت أذكار الصباح» و«لا تنسَ أذكارك» و«حان وقت الصلاة: صلاة العصر»', 'Gentle messages like: time for morning adhkar, prayer time: Asr')}</p>
      </div>

      {/* appearance + language */}
      <div className="rounded-2xl bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 p-4 shadow-soft">
        <p className="font-extrabold mb-2">🎨 {t(lang, 'المظهر واللغة', 'Appearance & language')}</p>
        <div className="grid grid-cols-2 gap-2">
          <button onClick={() => setTheme('light')} className={`rounded-xl py-2.5 text-sm font-bold border ${settings.theme === 'light' ? 'bg-amber-400 border-amber-400 text-slate-900' : 'border-slate-200 dark:border-slate-700'}`}>☀️ {t(lang, 'فاتح', 'Light')}</button>
          <button onClick={() => setTheme('dark')} className={`rounded-xl py-2.5 text-sm font-bold border ${settings.theme === 'dark' ? 'bg-slate-900 border-slate-900 text-white' : 'border-slate-200 dark:border-slate-700'}`}>🌙 {t(lang, 'داكن', 'Dark')}</button>
          <button onClick={() => setLang('ar')} className={`rounded-xl py-2.5 text-sm font-bold border ${settings.lang === 'ar' ? 'bg-emerald-600 text-white border-emerald-600' : 'border-slate-200 dark:border-slate-700'}`}>العربية</button>
          <button onClick={() => setLang('en')} className={`rounded-xl py-2.5 text-sm font-bold border ${settings.lang === 'en' ? 'bg-emerald-600 text-white border-emerald-600' : 'border-slate-200 dark:border-slate-700'}`}>English</button>
        </div>
      </div>

      <button onClick={() => { if (confirm(t(lang, 'إعادة تعيين كل الإعدادات؟', 'Reset all settings?'))) reset(); }} className="w-full rounded-2xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900 text-red-600 font-extrabold p-3.5 active:scale-[.99] transition">🗑️ {t(lang, 'إعادة تعيين كل الإعدادات', 'Reset all settings')}</button>

      <p className="text-center text-[11px] text-slate-400 pb-2">صلاتي وذكري 🕌 • {t(lang, 'جميع الأذكار موثقة بمصادرها', 'All adhkar are referenced')} • v1.0</p>
    </div>
  );
}
