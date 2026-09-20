// Adhan audio playback — plays the chosen adhan mp3 at prayer time.
import { getAdhanUrl } from './api';

let audioEl = null;
let unlocked = false;

// Call once on first user gesture so mobile browsers allow autoplay later.
export function unlockAdhanAudio() {
  if (unlocked) return;
  try {
    audioEl = audioEl || new Audio();
    audioEl.muted = true;
    const p = audioEl.play();
    if (p && p.catch) p.catch(() => {});
    audioEl.pause();
    audioEl.muted = false;
    unlocked = true;
  } catch { /* ignore */ }
}

export function playAdhan(settings) {
  const url = getAdhanUrl(settings);
  if (!url) return false;
  try {
    stopAdhan();
    audioEl = new Audio(url);
    audioEl.volume = Math.min(1, Math.max(0, Number(settings.adhanVolume ?? 0.9)));
    audioEl.play().catch(() => {});
    return true;
  } catch { return false; }
}

export function stopAdhan() {
  try {
    if (audioEl) { audioEl.pause(); audioEl.currentTime = 0; }
  } catch { /* ignore */ }
}
