import { useEffect, useState } from 'react';
import { qiblaBearing } from '../lib/api';

const t = (lang, ar, en) => (lang === 'ar' ? ar : en);

export default function Qibla({ settings, update }) {
  const lang = settings.lang;
  const [heading, setHeading] = useState(0);
  const [granted, setGranted] = useState(false);
  const bearing = qiblaBearing(Number(settings.lat) || 21.42, Number(settings.lng) || 39.82);
  const relative = ((bearing - heading) % 360 + 360) % 360;
  const aligned = Math.abs(relative) < 8 || Math.abs(relative - 360) < 8;

  useEffect(() => {
    const handler = (e) => {
      let h = null;
      if (e.webkitCompassHeading != null) h = e.webkitCompassHeading;
      else if (e.alpha != null) h = 360 - e.alpha;
      if (h != null) setHeading(h);
    };
    window.addEventListener('deviceorientationabsolute', handler, true);
    window.addEventListener('deviceorientation', handler, true);
    return () => {
      window.removeEventListener('deviceorientationabsolute', handler, true);
      window.removeEventListener('deviceorientation', handler, true);
    };
  }, []);

  const enableCompass = async () => {
    try {
      if (typeof DeviceOrientationEvent !== 'undefined' && DeviceOrientationEvent.requestPermission) {
        const r = await DeviceOrientationEvent.requestPermission();
        setGranted(r === 'granted');
      } else setGranted(true);
    } catch { setGranted(true); }
  };

  const locate = () => {
    if (!('geolocation' in navigator)) { alert(t(lang, 'الموقع غير مدعوم', 'Geolocation not supported')); return; }
    navigator.geolocation.getCurrentPosition(
      (pos) => update({ lat: +pos.coords.latitude.toFixed(4), lng: +pos.coords.longitude.toFixed(4), useCoords: true }),
      () => alert(t(lang, 'تعذّر تحديد الموقع', 'Could not get location')),
      { enableHighAccuracy: true }
    );
  };

  return (
    <div className="space-y-4 anim-fadeUp text-center">
      <h2 className="text-xl font-extrabold">🧭 {t(lang, 'اتجاه القبلة', 'Qibla direction')}</h2>

      <div className={`rounded-3xl p-6 shadow-soft border ${aligned ? 'bg-emerald-50 dark:bg-emerald-950/50 border-emerald-400' : 'bg-white dark:bg-slate-800 border-slate-100 dark:border-slate-700'}`}>
        {/* compass */}
        <div className="relative w-64 h-64 mx-auto">
          <div className="absolute inset-0 rounded-full border-8 border-emerald-600/20 bg-gradient-to-b from-slate-50 to-slate-100 dark:from-slate-700 dark:to-slate-800 shadow-inner" />
          {/* ticks */}
          <div className="absolute inset-0 compass-dial" style={{ transform: `rotate(${-heading}deg)` }}>
            <span className="absolute top-2 left-1/2 -translate-x-1/2 font-extrabold text-red-600">N</span>
            <span className="absolute bottom-2 left-1/2 -translate-x-1/2 font-bold text-slate-400">S</span>
            <span className="absolute right-3 top-1/2 -translate-y-1/2 font-bold text-slate-400">E</span>
            <span className="absolute left-3 top-1/2 -translate-y-1/2 font-bold text-slate-400">W</span>
            <div className="absolute inset-4 rounded-full border border-dashed border-slate-300 dark:border-slate-600" />
          </div>
          {/* qibla needle */}
          <div className="absolute inset-0 compass-dial" style={{ transform: `rotate(${relative}deg)` }}>
            <div className="absolute top-4 left-1/2 -translate-x-1/2 flex flex-col items-center">
              <span className="text-4xl drop-shadow">🕋</span>
              <div className="w-1 h-20 bg-gradient-to-b from-amber-500 to-amber-300 rounded-full mt-1" />
            </div>
          </div>
          {/* center */}
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-14 h-14 rounded-full bg-emerald-600 text-white flex items-center justify-center text-2xl shadow-lg">🧭</div>
        </div>

        <p className="mt-4 font-extrabold text-lg tabular-nums">{t(lang, 'زاوية القبلة', 'Qibla angle')}: {bearing.toFixed(1)}°</p>
        {aligned
          ? <p className="mt-1 font-extrabold text-emerald-600">✅ {t(lang, 'أنت متجه نحو القبلة الآن — تقبّل الله', 'You are facing the Qibla')}</p>
          : <p className="mt-1 text-sm text-slate-500">{t(lang, 'أدر هاتفك حتى تتجه علامة 🕋 للأعلى', 'Rotate your phone until 🕋 points up')}</p>}
      </div>

      <button onClick={enableCompass} className="w-full rounded-2xl bg-emerald-600 text-white font-extrabold p-3 active:scale-[.99] transition">📱 {t(lang, 'تفعيل البوصلة', 'Enable compass')}</button>

      <div className="rounded-2xl bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 p-4 text-right space-y-2">
        <p className="font-extrabold text-sm">📍 {t(lang, 'موقعك الحالي', 'Your location')}</p>
        <div className="grid grid-cols-2 gap-2">
          <label className="text-xs">Lat<input type="number" step="0.0001" value={settings.lat} onChange={(e) => update({ lat: Number(e.target.value) })} className="mt-1 w-full rounded-xl border p-2 tabular-nums bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700" /></label>
          <label className="text-xs">Lng<input type="number" step="0.0001" value={settings.lng} onChange={(e) => update({ lng: Number(e.target.value) })} className="mt-1 w-full rounded-xl border p-2 tabular-nums bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700" /></label>
        </div>
        <div className="flex gap-2">
          <button onClick={locate} className="flex-1 rounded-xl bg-sky-600 text-white font-bold py-2.5 text-sm active:scale-95 transition">🎯 {t(lang, 'تحديد موقعي GPS', 'Use GPS')}</button>
          <button onClick={() => update({ useCoords: !settings.useCoords })} className={`flex-1 rounded-xl font-bold py-2.5 text-sm active:scale-95 transition ${settings.useCoords ? 'bg-emerald-600 text-white' : 'bg-slate-100 dark:bg-slate-700'}`}>{settings.useCoords ? '✅ GPS مفعّل' : t(lang, 'استخدام الإحداثيات للمواقيت', 'Use coords for times')}</button>
        </div>
      </div>
    </div>
  );
}
