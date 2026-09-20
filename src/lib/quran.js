// Quran data layer — Hafs (Uthmani, api.alquran.cloud) + Warsh (fawazahmed0/quran-api).
// Surah audio: Alafasy (Hafs) + Yassin Al-Jazairi (Warsh). Cached for offline use.
import { SURAHS } from '../data/quranMeta';

export const RIWAYAT = [
  { id: 'hafs', ar: 'حفص عن عاصم', en: 'Hafs', short: 'حفص' },
  { id: 'warsh', ar: 'ورش عن نافع', en: 'Warsh', short: 'ورش' },
];

const SURAH_KEY = (n, riwaya) => `quran-surah-${riwaya}-${n}`;
const LASTREAD_KEY = 'quran-lastread-v1';

// cumulative ayah offsets → global ayah number (same Kufi counting for both riwayat)
const OFFSETS = (() => {
  const o = {};
  let acc = 0;
  for (const s of SURAHS) { o[s.n] = acc; acc += s.ayahs; }
  return o;
})();

async function fetchHafs(n) {
  const res = await fetch(`https://api.alquran.cloud/v1/surah/${n}/quran-uthmani`);
  if (!res.ok) throw new Error('تعذّر تحميل السورة');
  const json = await res.json();
  return json.data.ayahs.map((a) => ({
    g: a.number,
    n: a.numberInSurah,
    text: a.text,
    juz: a.juz,
    page: a.page,
  }));
}

async function fetchWarsh(n) {
  const res = await fetch(`https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ara-quranwarsh/${n}.min.json`);
  if (!res.ok) throw new Error('تعذّر تحميل السورة برواية ورش');
  const json = await res.json();
  return (json.chapter || []).map((v) => ({
    g: OFFSETS[n] + Number(v.verse),
    n: Number(v.verse),
    text: v.text,
    juz: null,
    page: null,
  }));
}

export async function fetchSurah(n, riwaya = 'hafs') {
  try {
    const raw = localStorage.getItem(SURAH_KEY(n, riwaya));
    if (raw) return JSON.parse(raw);
  } catch { /* ignore */ }
  const ayahs = riwaya === 'warsh' ? await fetchWarsh(n) : await fetchHafs(n);
  const data = { n, riwaya, ayahs };
  try { localStorage.setItem(SURAH_KEY(n, riwaya), JSON.stringify(data)); } catch { /* quota — ignore */ }
  return data;
}

// Download the complete Quran (114 surahs) for offline reading
export async function downloadAllQuran(onProgress, riwaya = 'hafs') {
  for (let n = 1; n <= 114; n++) {
    try {
      // eslint-disable-next-line no-await-in-loop
      await fetchSurah(n, riwaya);
    } catch { /* keep going */ }
    if (onProgress) onProgress(n, 114);
  }
}

export function countCachedSurahs(riwaya = 'hafs') {
  let c = 0;
  try {
    for (let n = 1; n <= 114; n++) if (localStorage.getItem(SURAH_KEY(n, riwaya))) c++;
  } catch { /* ignore */ }
  return c;
}

export function getLastRead() {
  try {
    const raw = localStorage.getItem(LASTREAD_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch { return null; }
}

export function setLastRead(surah, ayah, riwaya = 'hafs') {
  try { localStorage.setItem(LASTREAD_KEY, JSON.stringify({ surah, ayah, riwaya, at: Date.now() })); } catch { /* ignore */ }
}

// verse audio (Hafs — Alafasy)
export const ayahAudioUrl = (globalNum) =>
  `https://cdn.islamic.network/quran/audio/128/ar.alafasy/${globalNum}.mp3`;

// full-surah audio per riwaya
export const surahAudioUrl = (n, riwaya = 'hafs') =>
  riwaya === 'warsh'
    ? `https://cdn.islamic.network/quran/audio-surah/128/ar.yassenaljazairi/${n}.mp3`
    : `https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/${n}.mp3`;

// Arabic-Indic digits for verse markers: ١٢٣
export function arDigits(n) {
  return String(n).replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
}
