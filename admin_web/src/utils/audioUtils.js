// Modern Web Audio API Chime Synthesizer
// Works reliably across all browsers without requiring external audio asset files or dealing with CORS.

export const playNotificationChime = () => {
  try {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;

    const ctx = new AudioContext();

    // Pleasant double-tone notification chime (F5 -> A5)
    const playTone = (freq, startTime, duration) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, startTime);

      gain.gain.setValueAtTime(0.001, startTime);
      gain.gain.exponentialRampToValueAtTime(0.18, startTime + 0.04);
      gain.gain.exponentialRampToValueAtTime(0.001, startTime + duration);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(startTime);
      osc.stop(startTime + duration);
    };

    const now = ctx.currentTime;
    playTone(698.46, now, 0.18);        // F5
    playTone(880.00, now + 0.12, 0.35); // A5
  } catch (err) {
    console.warn('Could not play audio alert:', err);
  }
};
