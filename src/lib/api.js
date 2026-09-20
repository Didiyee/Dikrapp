// Prayer API (Aladhan) + helpers — accurate timings, Hijri date, Qibla

export const PRAYERS = [
  { key: 'Fajr', ar: 'الفجر', en: 'Fajr', icon: '🌅' },
  { key: 'Dhuhr', ar: 'الظهر', en: 'Dhuhr', icon: '☀️' },
  { key: 'Asr', ar: 'العصر', en: 'Asr', icon: '🌤️' },
  { key: 'Maghrib', ar: 'المغرب', en: 'Maghrib', icon: '🌇' },
  { key: 'Isha', ar: 'العشاء', en: 'Isha', icon: '🌙' },
];

export const METHODS = [
  { id: 0, ar: 'الشيعة الإثنا عشرية', en: 'Shia Ithna-Ansari' },
  { id: 1, ar: 'جامعة كراتشي', en: 'Karachi' },
  { id: 2, ar: 'أمريكا الشمالية (ISNA)', en: 'ISNA' },
  { id: 3, ar: 'رابطة العالم الإسلامي', en: 'Muslim World League' },
  { id: 4, ar: 'أم القرى (مكة)', en: 'Umm al-Qura' },
  { id: 5, ar: 'الهيئة المصرية', en: 'Egyptian Authority' },
  { id: 7, ar: 'طهران', en: 'Tehran' },
  { id: 8, ar: 'الخليج', en: 'Gulf' },
  { id: 9, ar: 'الكويت', en: 'Kuwait' },
  { id: 10, ar: 'قطر', en: 'Qatar' },
  { id: 13, ar: 'ديوان تركيا', en: 'Diyanet Turkey' },
  { id: 15, ar: 'فرنسا (UOIF)', en: 'France UOIF' },
  { id: 16, ar: 'روسيا', en: 'Russia' },
  { id: 18, ar: 'ماليزيا (JAKIM)', en: 'Malaysia' },
  { id: 19, ar: 'تونس', en: 'Tunisia' },
  { id: 20, ar: 'الجزائر', en: 'Algeria' },
  { id: 21, ar: 'المغرب', en: 'Morocco' },
];

const API = 'https://api.aladhan.com/v1';

function cleanTime(t) { return (t || '').split(' ')[0].slice(0, 5); }

export async function fetchTimings(settings) {
  const { useCoords, lat, lng, city, country, method, madhab } = settings;
  const school = madhab === 1 ? 1 : 0;
  const qs = new URLSearchParams({ method: String(method), school: String(school) });
  let url;
  if (useCoords && lat && lng) {
    const d = new Date();
    url = `${API}/timings/${String(d.getDate()).padStart(2,'0')}-${String(d.getMonth()+1).padStart(2,'0')}-${d.getFullYear()}?latitude=${lat}&longitude=${lng}&${qs}`;
  } else {
    url = `${API}/timingsByCity?city=${encodeURIComponent(city)}&country=${encodeURIComponent(country)}&${qs}`;
  }
  const res = await fetch(url);
  if (!res.ok) throw new Error('تعذّر جلب المواقيت');
  const json = await res.json();
  const t = json.data.timings;
  const timings = {};
  for (const p of PRAYERS) timings[p.key] = cleanTime(t[p.key]);
  return { timings, hijri: json.data.date.hijri, gregorian: json.data.date.gregorian };
}

export async function fetchMonthly(settings) {
  const { useCoords, lat, lng, city, country, method, madhab } = settings;
  const school = madhab === 1 ? 1 : 0;
  const now = new Date();
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const yyyy = now.getFullYear();
  let url;
  if (useCoords && lat && lng) {
    url = `${API}/calendar/${yyyy}/${mm}?latitude=${lat}&longitude=${lng}&method=${method}&school=${school}`;
  } else {
    url = `${API}/calendarByCity/${yyyy}/${mm}?city=${encodeURIComponent(city)}&country=${encodeURIComponent(country)}&method=${method}&school=${school}`;
  }
  const res = await fetch(url);
  if (!res.ok) throw new Error('تعذّر جلب التقويم الشهري');
  const json = await res.json();
  return json.data.map((d) => ({
    day: d.date.gregorian.day,
    hijriDay: d.date.hijri.day,
    hijriMonth: d.date.hijri.month.ar,
    timings: Object.fromEntries(PRAYERS.map((p) => [p.key, cleanTime(d.timings[p.key])])),
  }));
}

// Fallback local timings (approx) if offline
export function fallbackTimings() {
  return { Fajr: '05:00', Dhuhr: '12:15', Asr: '15:30', Maghrib: '18:05', Isha: '19:35' };
}

export function toMinutes(hhmm) {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
}

export function getNextPrayer(timings, now = new Date()) {
  const cur = now.getHours() * 60 + now.getMinutes();
  for (const p of PRAYERS) {
    if (toMinutes(timings[p.key]) > cur) return p;
  }
  return PRAYERS[0]; // الفجر غداً
}

export function getCurrentPrayer(timings, now = new Date()) {
  const cur = now.getHours() * 60 + now.getMinutes();
  let curP = PRAYERS[PRAYERS.length - 1];
  for (const p of PRAYERS) {
    if (toMinutes(p.key ? timings[p.key] : '') <= cur) curP = p;
  }
  return curP;
}

export function countdownTo(timeHHMM, now = new Date()) {
  let [h, m] = timeHHMM.split(':').map(Number);
  const target = new Date(now);
  target.setHours(h, m, 0, 0);
  if (target <= now) target.setDate(target.getDate() + 1);
  const diff = Math.max(0, target - now);
  const hh = Math.floor(diff / 3600000);
  const mm = Math.floor((diff % 3600000) / 60000);
  const ss = Math.floor((diff % 60000) / 1000);
  const pad = (n) => String(n).padStart(2, '0');
  return `${pad(hh)}:${pad(mm)}:${pad(ss)}`;
}

export function formatHijri(hijri, lang = 'ar') {
  if (!hijri) {
    try {
      return new Intl.DateTimeFormat(lang === 'ar' ? 'ar-SA-u-ca-islamic' : 'en-SA-u-ca-islamic', { day: 'numeric', month: 'long', year: 'numeric' }).format(new Date());
    } catch { return ''; }
  }
  if (lang === 'ar') return `${hijri.day} ${hijri.month.ar} ${hijri.year}هـ`;
  return `${hijri.day} ${hijri.month.en} ${hijri.year} AH`;
}

export function formatGregorian(gregorian, lang = 'ar') {
  try {
    const d = new Date();
    return new Intl.DateTimeFormat(lang === 'ar' ? 'ar-EG' : 'en-GB', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }).format(d);
  } catch { return gregorian?.date || ''; }
}

// Qibla bearing from (lat,lng) to Kaaba
export function qiblaBearing(lat, lng) {
  const kaabaLat = 21.4225 * Math.PI / 180;
  const kaabaLng = 39.8262 * Math.PI / 180;
  const phi = lat * Math.PI / 180;
  const lam = lng * Math.PI / 180;
  const dLam = kaabaLng - lam;
  const y = Math.sin(dLam);
  const x = Math.cos(phi) * Math.tan(kaabaLat) - Math.sin(phi) * Math.cos(dLam);
  const brng = Math.atan2(y, x) * 180 / Math.PI;
  return (brng + 360) % 360;
}

export function speakArabic(text, enabled = true) {
  if (!enabled) return;
  try {
    if (!('speechSynthesis' in window)) return;
    window.speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(text);
    u.lang = 'ar-SA';
    u.rate = 0.9;
    window.speechSynthesis.speak(u);
  } catch { /* ignore */ }
}

// ── تعديل يدوي للمواقيت (وقت دقيق يحدده المستخدم لكل صلاة، فارغ = تلقائي) ──
export function applyCustomTimes(timings, custom = {}) {
  if (!timings) return timings;
  const out = { ...timings };
  for (const k of Object.keys(out)) {
    const c = (custom[k] || '').trim();
    if (/^([01]\d|2[0-3]):[0-5]\d$/.test(c)) out[k] = c;
  }
  return out;
}

// ── أصوات الأذان ──
export const ADHAN_SOUNDS = [
  { id: 'makkah', ar: 'أذان مكة المكرمة', en: 'Makkah adhan', url: 'https://www.islamcan.com/audio/adhan/azan1.mp3' },
  { id: 'madinah', ar: 'أذان المدينة المنورة', en: 'Madinah adhan', url: 'https://www.islamcan.com/audio/adhan/azan2.mp3' },
  { id: 'aqsa', ar: 'أذان الأقصى', en: 'Al-Aqsa adhan', url: 'https://www.islamcan.com/audio/adhan/azan3.mp3' },
  { id: 'custom', ar: 'رابط مخصص', en: 'Custom URL', url: '' },
];

export function getAdhanUrl(settings) {
  if (settings.adhanSound === 'custom') return (settings.adhanCustomUrl || '').trim();
  return (ADHAN_SOUNDS.find((s) => s.id === settings.adhanSound) || ADHAN_SOUNDS[0]).url;
}
