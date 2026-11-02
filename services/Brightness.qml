pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.utils

Singleton {
    id: root

    // 0..1 on the shared scale; see Backlight.
    readonly property real level: root.available ? Backlight.toLevel(root.units, root.max) : 0
    property bool available: false

    // The backlight in the hardware's own units, as last read or asked for,
    // and at full.
    property int units: 0
    property int max: 0
    // The one brightnessctl picks, found by the first reading.
    property string device: ""

    // `units` was asked for while a write was still running. Dragging a slider
    // asks far faster than brightnessctl can answer; only the newest request
    // matters, so each one replaces the last.
    property bool unwritten: false

    // The backlight changed while a write was under way, and is read again
    // once it is done.
    property bool stale: false

    // The backlight was turned up or down: the brightness keys, the
    // dashboard, another app. Not when it first reports.
    signal adjusted()

    function setLevel(v: real): void {
        root.setUnits(Backlight.toUnits(Math.max(0, Math.min(1, v)), root.max));
    }

    function step(direction: int): void {
        root.setUnits(Backlight.step(root.units, root.max, direction));
    }

    // Nothing to write to before the first reading, nor without a backlight.
    function setUnits(units: int): void {
        if (!root.available || units === root.units)
            return;
        root.units = units;
        root.unwritten = true;
        root.flush();
        root.adjusted();
    }

    function flush(): void {
        if (!root.unwritten || writer.running)
            return;
        writer.command = ["brightnessctl", "-q", "set", `${root.units}`];
        root.unwritten = false;
        writer.running = true;
    }

    // A reading taken while a write is under way may be from before it, and
    // would put the slider back under the pointer, or the pill a step behind.
    // This service's own writes read back as what they set, and change
    // nothing.
    function read(text: string): void {
        if (writer.running || root.unwritten) {
            root.stale = true;
            return;
        }
        const units = parseInt(text);
        if (isNaN(units) || units === root.units)
            return;
        root.units = units;
        root.adjusted();
    }

    // brightnessctl -m: device,class,current,percent,max
    function parse(text: string): void {
        const parts = text.trim().split("\n")[0].split(",");
        const max = Number(parts[4]);
        if (parts.length < 5 || !(max > 0))
            return;
        root.device = parts[0];
        root.units = Number(parts[2]);
        root.max = max;
        root.available = true;
    }

    // One reading at startup: it decides whether the dashboard has a brightness
    // row at all, so the first open is already the right height instead of
    // growing a row while it animates. shell.qml starts this.
    Component.onCompleted: reader.running = true

    Connections {
        target: Compositor

        function onBrightnessPressed(direction: int): void {
            root.step(direction);
        }
    }

    Process {
        id: reader

        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    // After that, the level is read from the kernel, which announces every
    // change of the backlight, whoever made it. Its file cannot be watched:
    // a change to it raises nothing a watcher would hear.
    FileView {
        id: current

        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        onLoaded: root.read(current.text())
    }

    Process {
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=backlight"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (line.includes(" change "))
                    current.reload();
            }
        }
    }

    // The next write if one was asked for meanwhile, or else whatever changed
    // during this one.
    Process {
        id: writer

        onRunningChanged: {
            if (running)
                return;
            root.flush();
            if (!writer.running && root.stale) {
                root.stale = false;
                current.reload();
            }
        }
    }
}
