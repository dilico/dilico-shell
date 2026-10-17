pragma Singleton

import Quickshell
import qs.config

// Which glyph shows a state. Each function answers from its arguments alone,
// so the same state draws the same glyph wherever it is shown.
Singleton {
    id: root

    // How many of four bars a signal fills, so the pill's glyph and the
    // network list's bars agree. strength: 0..1
    function bars(strength: real): int {
        return Math.max(1, Math.min(4, Math.floor(strength * 4) + 1));
    }

    // strength: 0..1
    function wifi(connected: bool, strength: real): string {
        if (!connected)
            return Glyphs.wifiOff;
        return [Glyphs.wifi1, Glyphs.wifi2, Glyphs.wifi3, Glyphs.wifi4][root.bars(strength) - 1];
    }

    function bluetooth(enabled: bool, connected: int): string {
        if (!enabled)
            return Glyphs.bluetoothOff;
        return connected > 0 ? Glyphs.bluetoothConnected : Glyphs.bluetooth;
    }

    // A device, by the kind its service names it (Bluez.kind, Audio.kind);
    // Glyphs has an entry under each kind's name.
    function device(kind: string): string {
        return Glyphs[kind] ?? Glyphs.bluetooth;
    }

    // level: 0..1
    function volume(muted: bool, level: real): string {
        if (muted)
            return Glyphs.volumeOff;
        return level < 0.4 ? Glyphs.volumeLow : Glyphs.volume;
    }
}
