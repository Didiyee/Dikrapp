import { useMemo, useState } from 'react';
import { CATEGORIES, ADHKAR } from '../data/adhkar';
import { speakArabic } from '../lib/api';
import { uid } from '../lib/store';

const t = (lang, ar, en) => (lang === 'ar' ? ar : en);

function DhikrCard({ d, settings, setSettings, lang }) {
  const total = d.repeat;
  const remaining = settings.counters[d.id] ?? total;
  const done = total - remaining;
  const pct = total === 0 ? 100 : Math.round((done / total) * 100);
  const isFav = settings.favorites.includes(d.id);
  const completed = remaining <= 0;

  const tap = () => {
    if (remaining <= 0) return;
    setSettings((s) => ({ ...s, counters: { ...s.counters, [d.id]: remaining - 1 } }));
  };
  const reset = (e) => {
    e.stopPropagation();
    setSettings((s) => ({ ...s, counters: { ...s.counters, [d.id]: total } }));
  };
  const fav = (e) => {
    e.stopPropagation();
    setSettings((s) => ({
      ...s,
      favorites: isFav ? s.favorites.filter((x) => x !== d.id) : [...s.favorites, d.id],
    }));
  };

  return (
    <div className={`rounded-2xl border p-4 shadow-soft transition ${completed ? 'bg-emerald-50 dark:bg-emerald-950/40 border-emerald-400' : 'bg-white dark:bg-slate-800 border-slate-100 dark:border-slate-700'}`}>
      <p className="font-quran text-lg leading-[2.1] text-slate-800 dark:text-slate-100">{d.text}</p>
      {d.virtue && <p className="text-xs text-emerald-700 dark:text-emerald-300 mt-2">✨ {d.virtue}</p>}
      {d.source && <p className="text-[11px] text-slate-400 mt-1">📚 {d.source}</p>}

      {/* progress */}
      <div className="mt-3 h-2 rounded-full bg-slate-100 dark:bg-slate-700 overflow-hidden">
        <div className="h-full bg-gradient-to-l from-emerald-500 to-amber-400 transition-all" style={{ width: `${pct}%` }} />
      </div>

      <div className="flex items-center gap-2 mt-3">
        <button onClick={tap} disabled={completed} className={`flex-1 rounded-2xl py-3 font-extrabold text-lg active:scale-95 transition tabular-nums ${completed ? 'bg-emerald-600 text-white' : 'bg-emerald-600 text-white hover:bg-emerald-700'}`}>
          {completed ? `✅ ${t(lang, 'تم — تقبّل الله', 'Done')}` : `👆 ${t(lang, 'اضغط للتسبيح', 'Tap to count')} • ${t(lang, 'المتبقي', 'left')}: ${remaining}/${total}`}
        </button>
        <button onClick={reset} title={t(lang, 'إعادة', 'Reset')} className="px-3 py-3 rounded-2xl bg-slate-100 dark:bg-slate-700 active:scale-90 transition">🔄</button>
        <button onClick={fav} title={t(lang, 'مفضلة', 'Bookmark')} className={`px-3 py-3 rounded-2xl active:scale-90 transition ${isFav ? 'bg-amber-200 dark:bg-amber-800' : 'bg-slate-100 dark:bg-slate-700'}`}>{isFav ? '⭐' : '☆'}</button>
        <button onClick={(e) => { e.stopPropagation(); speakArabic(d.text, true); }} title={t(lang, 'استماع', 'Listen')} className="px-3 py-3 rounded-2xl bg-sky-100 dark:bg-sky-900/50 active:scale-90 transition">🔊</button>
      </div>
    </div>
  );
}

export default function Adhkar({ settings, setSettings, initialCat }) {
  const lang = settings.lang;
  const [tab, setTab] = useState(initialCat === 'fav' ? 'fav' : initialCat === 'notes' ? 'notes' : 'cats');
  const [cat, setCat] = useState(CATEGORIES.some((c) => c.id === initialCat) ? initialCat : 'morning');
  const [q, setQ] = useState('');
  // notes form
  const [nTitle, setNTitle] = useState('');
  const [nText, setNText] = useState('');

  const list = useMemo(() => {
    let arr = ADHKAR.filter((d) => d.cat === cat);
    if (q.trim()) arr = ADHKAR.filter((d) => d.text.includes(q.trim()));
    return arr;
  }, [cat, q]);

  const favList = ADHKAR.filter((d) => settings.favorites.includes(d.id));
  const catMeta = (id) => CATEGORIES.find((c) => c.id === id);

  const addNote = () => {
    if (!nText.trim()) return;
    setSettings((s) => ({ ...s, notes: [{ id: uid(), title: nTitle.trim() || t(lang, 'ملاحظة', 'Note'), text: nText.trim(), createdAt: new Date().toLocaleString(lang === 'ar' ? 'ar-EG' : 'en-GB') }, ...s.notes] }));
    setNTitle(''); setNText('');
  };
  const delNote = (id) => setSettings((s) => ({ ...s, notes: s.notes.filter((n) => n.id !== id) }));

  return (
    <div className="space-y-4 anim-fadeUp">
      <h2 className="text-xl font-extrabold">📿 {t(lang, 'الأذكار', 'Adhkar')}</h2>

      {/* tabs: categories / bookmarks / booknotes */}
      <div className="grid grid-cols-3 gap-2 bg-slate-100 dark:bg-slate-800 p-1.5 rounded-2xl">
        {[
          { id: 'cats', label: `🗂️ ${t(lang, 'التصنيفات', 'Categories')}` },
          { id: 'fav', label: `⭐ ${t(lang, 'المحفوظات', 'Bookmarks')} (${settings.favorites.length})` },
          { id: 'notes', label: `📝 ${t(lang, 'دفتر الملاحظات', 'Booknotes')} (${settings.notes.length})` },
        ].map((x) => (
          <button key={x.id} onClick={() => setTab(x.id)} className={`rounded-xl py-2.5 text-xs font-extrabold transition active:scale-95 ${tab === x.id ? 'bg-white dark:bg-slate-700 shadow text-emerald-700 dark:text-emerald-300' : 'text-slate-500 dark:text-slate-400'}`}>{x.label}</button>
        ))}
      </div>

      {tab === 'cats' && (
        <>
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder={t(lang, '🔍 ابحث في الأذكار...', 'Search adhkar...')} className="w-full rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 p-3 text-sm outline-none focus:border-emerald-500" />
          {!q && (
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
              {CATEGORIES.map((c) => (
                <button key={c.id} onClick={() => setCat(c.id)} className={`rounded-2xl p-3 border text-right active:scale-95 transition ${cat === c.id ? 'bg-emerald-600 text-white border-emerald-600 shadow-soft' : 'bg-white dark:bg-slate-800 border-slate-100 dark:border-slate-700'}`}>
                  <div className="text-2xl">{c.icon}</div>
                  <div className="text-xs font-extrabold mt-1 leading-tight">{t(lang, c.ar, c.en)}</div>
                  <div className="text-[11px] opacity-70">{ADHKAR.filter((d) => d.cat === c.id).length} {t(lang, 'ذكر', 'items')}</div>
                </button>
              ))}
            </div>
          )}
          <p className="text-sm font-bold text-slate-500">{q ? `${t(lang, 'نتائج البحث', 'Results')}: ${list.length}` : `${catMeta(cat) ? t(lang, catMeta(cat).ar, catMeta(cat).en) : ''} (${list.length})`}</p>
          <div className="space-y-3">
            {list.map((d) => <DhikrCard key={d.id} d={d} settings={settings} setSettings={setSettings} lang={lang} />)}
            {list.length === 0 && <p className="text-center text-slate-400 py-8">لا توجد نتائج — جرّب كلمة أخرى</p>}
          </div>
        </>
      )}

      {tab === 'fav' && (
        <div className="space-y-3">
          <p className="text-sm text-slate-500">⭐ {t(lang, 'الأذكار المحفوظة (Bookmarks) — اضغط ☆ لحفظ أي ذكر', 'Your bookmarked adhkar — tap ☆ on any dhikr to save it here')}</p>
          {favList.length === 0 && <div className="text-center py-10 text-slate-400">لا توجد محفوظات بعد<br />⭐ اضغط على ☆ بجانب أي ذكر لحفظه هنا</div>}
          {favList.map((d) => (
            <div key={d.id}>
              <p className="text-[11px] font-bold text-amber-600 mb-1">{catMeta(d.cat)?.icon} {t(lang, catMeta(d.cat)?.ar || '', catMeta(d.cat)?.en || '')}</p>
              <DhikrCard d={d} settings={settings} setSettings={setSettings} lang={lang} />
            </div>
          ))}
        </div>
      )}

      {tab === 'notes' && (
        <div className="space-y-3">
          <div className="rounded-2xl bg-white dark:bg-slate-800 border border-sky-200 dark:border-slate-700 p-4 shadow-soft">
            <p className="font-extrabold text-sm mb-2">📝 {t(lang, 'إضافة ملاحظة جديدة (Booknote)', 'Add a new booknote')}</p>
            <input value={nTitle} onChange={(e) => setNTitle(e.target.value)} placeholder={t(lang, 'العنوان (مثال: وردي اليومي)', 'Title')} className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 p-2.5 text-sm mb-2 outline-none focus:border-sky-500" />
            <textarea value={nText} onChange={(e) => setNText(e.target.value)} rows={3} placeholder={t(lang, 'اكتب ملاحظتك: آية أثّرت فيك، دعاء تريد تكراره، خاطرة إيمانية...', 'Write: a verse, a dua to repeat, a reflection...')} className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 p-2.5 text-sm outline-none focus:border-sky-500" />
            <button onClick={addNote} className="mt-2 w-full bg-sky-600 text-white font-extrabold rounded-xl py-2.5 active:scale-95 transition">➕ {t(lang, 'حفظ الملاحظة', 'Save note')}</button>
          </div>
          {settings.notes.length === 0 && <p className="text-center text-slate-400 py-6">دفترك فارغ — ابدأ بتدوين أول خاطرة إيمانية 📝</p>}
          {settings.notes.map((n) => (
            <div key={n.id} className="rounded-2xl bg-amber-50 dark:bg-slate-800 border border-amber-200 dark:border-slate-700 p-4">
              <div className="flex items-start justify-between gap-2">
                <p className="font-extrabold text-sm">📌 {n.title}</p>
                <button onClick={() => delNote(n.id)} className="text-red-500 text-sm px-2 py-1 rounded-lg bg-red-50 dark:bg-red-950/40 active:scale-90">🗑️</button>
              </div>
              <p className="text-sm mt-1 leading-7 whitespace-pre-wrap text-slate-700 dark:text-slate-200">{n.text}</p>
              <p className="text-[11px] text-slate-400 mt-2">{n.createdAt}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
