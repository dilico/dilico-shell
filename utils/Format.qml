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

    // 0..1 as a percentage to a tenth, for shares mostly under one per cent:
    // 0.0234 is "2.3%".
    function percentTenths(fraction: real): string {
        return `${(fraction * 100).toFixed(1)}%`;
    }

    // Bytes as megabytes under a gigabyte, gigabytes to a tenth above:
    // "340m", "1.2g".
    function size(bytes: real): string {
        const gib = bytes / 1073741824;
        return gib < 1 ? `${Math.round(bytes / 1048576)}m` : `${gib.toFixed(1)}g`;
    }

    // 0..1 as a percentage, or "off" when muted: 0.59 is "59%".
    function percentOrOff(muted: bool, fraction: real): string {
        return muted ? "off" : root.percent(fraction);
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

    // A weekday by Locale's number, 0 for Sunday, short and lower case:
    // "mon".
    function weekday(day: int): string {
        return Qt.locale().dayName(day, Locale.ShortFormat).toLowerCase();
    }

    // A position in a track: 187 seconds is "3:07".
    function playTime(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    // How long ago a moment was, in its largest whole unit: "just now",
    // "5m ago", "3h ago", "2d ago". Both in seconds since the epoch.
    function ago(then: real, now: real): string {
        const s = Math.max(0, now - then);
        if (s < 60)
            return "just now";
        if (s < 3600)
            return `${Math.floor(s / 60)}m ago`;
        if (s < 86400)
            return `${Math.floor(s / 3600)}h ago`;
        return `${Math.floor(s / 86400)}d ago`;
    }

    // A span to the nearest minute: "45m", "1h05m".
    function duration(seconds: real): string {
        const m = Math.round(seconds / 60);
        return m >= 60 ? `${Math.floor(m / 60)}h${String(m % 60).padStart(2, "0")}m` : `${m}m`;
    }

    // A monitor by what a person calls it: "built-in" for a laptop's own
    // panel, whose model is only its maker's part number, else its model,
    // else its port.
    function monitor(builtIn: bool, model: string, port: string): string {
        if (builtIn)
            return "built-in";
        return model || port;
    }

    // A mode's size: "1920 × 1200".
    function resolution(width: int, height: int): string {
        return `${width} × ${height}`;
    }

    // A refresh rate, whole unless it is not: "60 hz", "59.94 hz".
    function refresh(hz: real): string {
        return Math.abs(hz - Math.round(hz)) < 0.01 ? `${Math.round(hz)} hz` : `${hz.toFixed(2)} hz`;
    }
}
