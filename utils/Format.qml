pragma Singleton

import QtQuick
import Quickshell

// Numbers and dates as the shell writes them. Each function answers from its
// arguments alone.
Singleton {
    id: root

    // 0..1 as a whole percentage: 0.427 is "43%".
    function percent(fraction: real): string {
        return `${Math.round(fraction * 100)}%`;
    }

    // The time of day, 24-hour: "09:41".
    function time(d: date): string {
        return Qt.formatDateTime(d, "HH:mm");
    }

    // A date in any Qt pattern, lower case like all of the shell's text:
    // "ddd dd" is "fri 16".
    function date(d: date, pattern: string): string {
        return Qt.formatDateTime(d, pattern).toLowerCase();
    }

    // A position in a track: 187 seconds is "3:07".
    function playTime(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    // A span to the nearest minute: "45m", "1h05m".
    function duration(seconds: real): string {
        const m = Math.round(seconds / 60);
        return m >= 60 ? `${Math.floor(m / 60)}h${String(m % 60).padStart(2, "0")}m` : `${m}m`;
    }
}
