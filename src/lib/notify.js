// Notifications: permission + fire + gentle beep/vibration
export async function ensurePermission() {
  try {
    if (!('Notification' in window)) return false;
    if (Notification.permission === 'granted') return true;
    const p = await Notification.requestPermission();
    return p === 'granted';
  } catch { return false; }
}

export function fireNotification(title, body) {
  try {
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification(title, { body, icon: '🕌', dir: 'rtl', lang: 'ar' });
    }
  } catch { /* ignore — fallback below */ }
}

export function gentleAlert(settings) {
  try {
    if (settings.vibration && 'vibrate' in navigator) navigator.vibrate([200, 100, 200]);
    if (settings.sound) {
      const ctx = new (window.AudioContext || window.webkitAudioContext)();
      const o = ctx.createOscillator();
      const g = ctx.createGain();
      o.connect(g); g.connect(ctx.destination);
      o.frequency.value = 660;
      g.gain.setValueAtTime(0.08, ctx.currentTime);
      o.start();
      o.stop(ctx.currentTime + 0.6);
    }
  } catch { /* ignore */ }
}

export function notify(title, body, settings) {
  fireNotification(title, body);
  gentleAlert(settings);
}
