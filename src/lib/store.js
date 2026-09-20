import { useEffect, useState } from 'react';

export const DEFAULT_SETTINGS = {
  city: 'Makkah al-Mukarramah',
  cityAr: 'مكة المكرمة',
  country: 'Saudi Arabia',
  countryAr: 'السعودية',
  method: 4, // أم القرى
  madhab: 0, // 0 شافعي / 1 حنفي
  lang: 'ar',
  theme: 'light',
  useCoords: false,
  lat: 21.4225,
  lng: 39.8262,
  prayerNotifs: { Fajr: true, Dhuhr: true, Asr: true, Maghrib: true, Isha: true },
  adhkarReminders: true,
  morningReminder: '05:00',
  eveningReminder: '16:30',
  nightReminder: '22:00',
  sound: true,
  vibration: true,
  // ── الأذان ──
  adhanEnabled: true,
  adhanSound: 'makkah', // makkah|madinah|aqsa|custom
  adhanCustomUrl: '',
  adhanVolume: 0.9,
  // ── تعديل يدوي لمواقيت الصلاة (وقت دقيق لكل صلاة، فارغ = تلقائي) ──
  customTimes: { Fajr: '', Dhuhr: '', Asr: '', Maghrib: '', Isha: '' },
  favorites: [],
  counters: {}, // {dhikrId: remaining}
  notes: [], // {id,title,text,createdAt}
  quranRiwaya: 'hafs', // hafs | warsh
};

const KEY = 'salati-dhikri-settings-v1';

export function loadSettings() {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return { ...DEFAULT_SETTINGS };
    return { ...DEFAULT_SETTINGS, ...JSON.parse(raw) };
  } catch {
    return { ...DEFAULT_SETTINGS };
  }
}

export function saveSettings(s) {
  try { localStorage.setItem(KEY, JSON.stringify(s)); } catch { /* ignore */ }
}

export function useSettings() {
  const [settings, setSettings] = useState(loadSettings);
  useEffect(() => { saveSettings(settings); }, [settings]);
  const update = (patch) => setSettings((s) => ({ ...s, ...patch }));
  const reset = () => setSettings({ ...DEFAULT_SETTINGS });
  return [settings, update, setSettings, reset];
}

export const uid = () => Math.random().toString(36).slice(2, 10) + Date.now().toString(36).slice(-4);
