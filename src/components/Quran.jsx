import { useEffect, useRef, useState } from 'react';
import { SURAHS, BISMILLAH } from '../data/quranMeta';
import { RIWAYAT, fetchSurah, downloadAllQuran, countCachedSurahs, getLastRead, setLastRead, ayahAudioUrl, surahAudioUrl, arDigits } from '../lib/quran';

const t = (lang, ar, en) => (lang === 'ar' ? ar : en);

export default function Quran({ lang, riwaya = 'hafs', onRiwaya }) {
  const [view, setView] = useState(null); // surah number or null (list)
  const [q, setQ] = useState('');
  const [ayahs, setAyahs] = useState(null);
  const [loading, setLoading] = useState(false);
  const [fontSize, setFontSize] = useState(22);
  const [playing, setPlaying] = useState(null); // global ayah number or 'surah'
  const [cached, setCached] = useState(countCachedSurahs(riwaya));
  const [dlProgress, setDlProgress] = useState(null);
  const [lastRead, setLastReadState] = useState(getLastRead());
  const audioRef = useRef(null);

  const openSurah = async (n, r = riwaya) => {
    setView(n);
    setAyahs(null);
    setLoading(true);
    stopAudio();
    try {
      const d = await fetchSurah(n, r);
      setAyahs(d.ayahs);
      setCached(countCachedSurahs(r));
    } catch {
      setAyahs([]);
    }
    setLoading(false);
    window.scrollTo({ top: 0 });
  };

  // reload current surah when riwaya changes
  const switchRiwaya = (r) => {
    onRiwaya(r);
    setCached(countCachedSurahs(r));
    if (view) openSurah(view, r);
  };

  const stopAudio = () => {
    try { audioRef.current?.pause(); } catch { /* ignore */ }
    setPlaying(null);
  };

  useEffect(() => () => { try { audioRef.current?.pause(); } catch { /* ignore */ } }, []);

  const getAudio = () => audioRef.current || (audioRef.current = new Audio());

  // Hafs: verse-by-verse with chaining + highlight
  const playAyah = (a, autoNext) => {
    try { audioRef.current?.pause(); } catch { /* ignore */ }
    const audio = getAudio();
    audio.src = ayahAudioUrl(a.g);
    setPlaying(a.g);
    audio.onended = () => {
      if (autoNext && ayahs) {
        const i = ayahs.findIndex((x) => x.g === a.g);
        if (i >= 0 && i + 1 < ayahs.length) playAyah(ayahs[i + 1], true);
        else stopAudio();
      } else stopAudio();
    };
    audio.onerror = () => stopAudio();
    audio.play().catch(() => stopAudio());
  };

  // Warsh (and fallback): whole-surah audio file
  const playSurahAudio = () => {
    try { audioRef.current?.pause(); } catch { /* ignore */ }
    const audio = getAudio();
    audio.src = surahAudioUrl(view, riwaya);
    setPlaying('surah');
    audio.onended = () => stopAudio();
    audio.onerror = () => stopAudio();
    audio.play().catch(() => stopAudio());
  };

  const markRead = (a) => {
    setLastRead(view, a.n, riwaya);
    setLastReadState(getLastRead());
  };

  const downloadAll = async () => {
    setDlProgress({ done: 0, total: 114 });
    await downloadAllQuran((done, total) => setDlProgress({ done, total }), riwaya);
    setCached(countCachedSurahs(riwaya));
    setDlProgress(null);
  };

  const filtered = SURAHS.filter((s) =>
    !q.trim() || s.ar.includes(q.trim()) || s.en.toLowerCase().includes(q.trim().toLowerCase()) || String(s.n) === q.trim()
  );
  const meta = view ? SURAHS[view - 1] : null;
  const riwayaName = riwaya === 'warsh' ? t(lang, 'ورش عن نافع', 'Warsh') : t(lang, 'حفص عن عاصم', 'Hafs');
  const reciter = riwaya === 'warsh' ? t(lang, 'ياسين الجزائري (ورش)', 'Yassin Al-Jazairi (Warsh)') : t(lang, 'مشاري العفاسي (حفص)', 'Mishary Alafasy (Hafs)');

  // ── reader ──
  if (view && meta) {
    return (
      <div className="space-y-3 anim-fadeUp">
        <div className="flex items-center gap-2">
          <button onClick={() => { stopAudio(); setView(null); setAyahs(null); }} className="bg-slate-100 dark:bg-slate-700 rounded-xl px-3 py-2 font-bold active:scale-95">→ {t(lang, 'السور', 'Surahs')}</button>
          <h2 className="text-lg font-extrabold flex-1 text-center">📖 {t(lang, `سورة ${meta.ar}`, `${meta.en}`)} <span className="text-xs text-slate-400">({meta.ayahs} {t(lang, 'آية', 'verses')})</span></h2>
        </div>

        <div className="grid grid-cols-2 gap-2 bg-slate-100 dark:bg-slate-800 p-1.5 rounded-2xl">
          {RIWAYAT.map((r) => (
            <button key={r.id} onClick={() => switchRiwaya(r.id)} className={`rounded-xl py-2 text-xs font-extrabold transition active:scale-95 ${riwaya === r.id ? 'bg-white dark:bg-slate-700 shadow text-emerald-700 dark:text-emerald-300' : 'text-slate-500 dark:text-slate-400'}`}>
              {t(lang, `رواية ${r.ar}`, r.en)}
            </button>
          ))}
        </div>

        <div className="flex items-center gap-2 flex-wrap">
          {riwaya === 'hafs'
            ? <button onClick={() => ayahs?.length && playAyah(ayahs[0], true)} className="flex-1 min-w-[140px] rounded-xl bg-emerald-600 text-white font-extrabold py-2.5 text-sm active:scale-95">▶️ {t(lang, 'تلاوة السورة آية آية', 'Recite verse by verse')}</button>
            : <button onClick={playSurahAudio} className="flex-1 min-w-[140px] rounded-xl bg-emerald-600 text-white font-extrabold py-2.5 text-sm active:scale-95">▶️ {t(lang, 'تلاوة السورة كاملة (ورش)', 'Recite full surah (Warsh)')}</button>}
          {playing && <button onClick={stopAudio} className="rounded-xl bg-red-500 text-white font-bold px-4 py-2.5 text-sm active:scale-95">⏹️</button>}
          <div className="flex items-center gap-1 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl px-2 py-1.5 text-sm">
            <button onClick={() => setFontSize((s) => Math.max(16, s - 2))} className="px-2 font-extrabold">أ−</button>
            <span className="tabular-nums text-xs">{fontSize}</span>
            <button onClick={() => setFontSize((s) => Math.min(34, s + 2))} className="px-2 font-extrabold">أ+</button>
          </div>
        </div>

        {loading && <p className="text-center py-10 text-slate-400">⏳ {t(lang, 'جارٍ تحميل السورة...', 'Loading surah...')}</p>}
        {!loading && ayahs?.length === 0 && <p className="text-center py-10 text-slate-400">{t(lang, 'تعذّر التحميل — تحقق من الإنترنت', 'Failed to load — check internet')}</p>}

        {ayahs?.length > 0 && (
          <div className="rounded-3xl bg-white dark:bg-slate-800 border border-amber-200 dark:border-slate-700 shadow-soft p-5">
            <p className="text-center text-xs font-bold text-emerald-700 dark:text-emerald-300 mb-1">📜 {t(lang, `النص برواية ${riwayaName}`, `${riwayaName} text`)}</p>
            {view !== 1 && view !== 9 && <p className="font-quran text-center text-2xl mb-4 text-emerald-700 dark:text-emerald-300">{BISMILLAH}</p>}
            <div className="font-quran leading-[2.4] text-justify" style={{ fontSize }}>
              {ayahs.map((a) => (
                <span key={a.g}>
                  <span
                    onClick={() => markRead(a)}
                    className={`rounded px-0.5 ${playing === a.g ? 'bg-amber-200 dark:bg-amber-800' : ''}`}
                  >
                    {a.text}
                  </span>{' '}
                  {riwaya === 'hafs' && (
                    <button
                      onClick={() => (playing === a.g ? stopAudio() : playAyah(a, false))}
                      title={t(lang, 'استماع', 'Listen')}
                      className={`inline-flex items-center justify-center min-w-[2.2em] h-[1.7em] px-1 rounded-full border text-[0.65em] font-sans align-middle mx-0.5 active:scale-90 ${playing === a.g ? 'bg-emerald-600 text-white border-emerald-600' : 'border-emerald-400 text-emerald-700 dark:text-emerald-300'}`}
                    >
                      {playing === a.g ? '⏸' : `﴿${arDigits(a.n)}﴾ 🔊`}
                    </button>
                  )}
                  {riwaya === 'warsh' && <span className="inline-flex items-center justify-center min-w-[2.2em] h-[1.7em] px-1 rounded-full border border-amber-400 text-amber-700 dark:text-amber-300 text-[0.65em] font-sans align-middle mx-0.5">﴿{arDigits(a.n)}﴾</span>}{' '}
                </span>
              ))}
            </div>
            <p className="text-center text-[11px] text-slate-400 mt-4">📖 {t(lang, 'اضغط على أي آية لحفظ موضع القراءة', 'Tap any verse to save your reading position')} • 🔊 {reciter}</p>
          </div>
        )}
      </div>
    );
  }

  // ── surah list ──
  return (
    <div className="space-y-3 anim-fadeUp">
      <h2 className="text-xl font-extrabold">📖 {t(lang, 'القرآن الكريم كاملاً', 'The Holy Quran')}</h2>

      <div className="grid grid-cols-2 gap-2 bg-slate-100 dark:bg-slate-800 p-1.5 rounded-2xl">
        {RIWAYAT.map((r) => (
          <button key={r.id} onClick={() => switchRiwaya(r.id)} className={`rounded-xl py-2.5 text-sm font-extrabold transition active:scale-95 ${riwaya === r.id ? 'bg-emerald-600 text-white shadow' : 'text-slate-500 dark:text-slate-400'}`}>
            📜 {t(lang, `رواية ${r.ar}`, `${r.en} narration`)}
          </button>
        ))}
      </div>

      {lastRead && (
        <button onClick={() => { if (lastRead.riwaya && lastRead.riwaya !== riwaya) onRiwaya(lastRead.riwaya); openSurah(lastRead.surah, lastRead.riwaya || riwaya); }} className="w-full text-right rounded-2xl bg-emerald-600 text-white p-3.5 font-bold active:scale-[.99] transition">
          🔖 {t(lang, 'أكمل القراءة', 'Continue reading')}: {t(lang, `سورة ${SURAHS[lastRead.surah - 1].ar}`, SURAHS[lastRead.surah - 1].en)} — {t(lang, 'آية', 'verse')} {lastRead.ayah} {lastRead.riwaya === 'warsh' ? t(lang, '(ورش)', '(Warsh)') : ''}
        </button>
      )}

      <input value={q} onChange={(e) => setQ(e.target.value)} placeholder={t(lang, '🔍 ابحث برقم السورة أو اسمها...', 'Search surah...')} className="w-full rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 p-3 text-sm outline-none focus:border-emerald-500" />

      <div className="rounded-2xl bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/40 p-3 text-sm flex items-center gap-2 flex-wrap">
        <span className="font-bold">💾 {t(lang, `محفوظ دون إنترنت (${riwayaName}): ${cached}/114`, `Offline (${riwayaName}): ${cached}/114`)} </span>
        {dlProgress
          ? <span className="font-extrabold tabular-nums">⏳ {dlProgress.done}/114</span>
          : <button onClick={downloadAll} className="mr-auto bg-amber-500 text-white text-xs font-extrabold px-3 py-2 rounded-xl active:scale-95">⬇️ {t(lang, 'تحميل المصحف كاملاً', 'Download full Quran')}</button>}
      </div>
      {dlProgress && <div className="h-2 rounded-full bg-slate-200 dark:bg-slate-700 overflow-hidden"><div className="h-full bg-amber-500 transition-all" style={{ width: `${(dlProgress.done / 114) * 100}%` }} /></div>}

      <div className="space-y-2">
        {filtered.map((s) => (
          <button key={s.n} onClick={() => openSurah(s.n)} className="w-full flex items-center gap-3 rounded-2xl bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 p-3 shadow-soft active:scale-[.99] transition text-right">
            <span className="w-10 h-10 shrink-0 rounded-xl bg-emerald-600 text-white font-extrabold flex items-center justify-center tabular-nums text-sm">{s.n}</span>
            <span className="flex-1">
              <span className="block font-extrabold">سورة {s.ar}</span>
              <span className="block text-[11px] text-slate-400">{s.en} • {s.ayahs} {t(lang, 'آية', 'verses')} • {s.makki ? t(lang, 'مكية', 'Meccan') : t(lang, 'مدنية', 'Medinan')}</span>
            </span>
            <span className="font-quran text-xl text-amber-500">۞</span>
          </button>
        ))}
      </div>
      <p className="text-center text-[11px] text-slate-400 pb-2">📖 {riwaya === 'warsh' ? t(lang, 'النص برواية ورش عن نافع — التلاوة: ياسين الجزائري', 'Warsh text — recitation: Yassin Al-Jazairi') : t(lang, 'النص بالرسم العثماني (حفص) — التلاوة: مشاري العفاسي', 'Uthmani text (Hafs) — recitation: Mishary Alafasy')}</p>
    </div>
  );
}
