pragma Singleton

import Quickshell
import qs.config

// Which glyph shows a state. Each function answers from its arguments alone,
// so the same state draws the same glyph wherever it is shown.
Singleton {
    id: root

    // strength: 0..1
    function wifi(connected: bool, strength: real): string {
        if (!connected)
            return Glyphs.wifiOff;
        return strength >= 0.75 ? Glyphs.wifi4 : strength >= 0.5 ? Glyphs.wifi3 : strength >= 0.25 ? Glyphs.wifi2 : Glyphs.wifi1;
    }

    function bluetooth(enabled: bool, connected: int): string {
        if (!enabled)
            return Glyphs.bluetoothOff;
        return connected > 0 ? Glyphs.bluetoothConnected : Glyphs.bluetooth;
    }

    // level: 0..1
    function volume(muted: bool, level: real): string {
        if (muted)
            return Glyphs.volumeOff;
        return level < 0.4 ? Glyphs.volumeLow : Glyphs.volume;
    }
}
