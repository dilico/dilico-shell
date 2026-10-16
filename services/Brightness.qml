pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // How many things are showing the level, each through a Watch.
    // brightnessctl is only polled while something is looking: the backlight
    // emits nothing to listen for.
    property int watchers: 0

    // 0..1, linear in the hardware's own units.
    property real level: 0
    property bool available: false

    // The latest level asked for while a write was still running. Dragging a
    // slider asks far faster than brightnessctl can answer; only the newest
    // request matters, so each one replaces the last.
    property real pending: -1

    function setLevel(v: real): void {
        // Never fully black: a 0 here leaves no way to see the slider again.
        const clamped = Math.max(0.01, Math.min(1, v));
        root.level = clamped;
        root.pending = clamped;
        if (!writer.running)
            root.flush();
    }

    function flush(): void {
        if (root.pending < 0)
            return;
        writer.command = ["brightnessctl", "-q", "set", `${Math.round(root.pending * 100)}%`];
        root.pending = -1;
        writer.running = true;
    }

    // brightnessctl -m: device,class,current,percent,max
    function parse(text: string): void {
        const parts = text.trim().split("\n")[0].split(",");
        if (parts.length < 5)
            return;
        const current = Number(parts[2]);
        const max = Number(parts[4]);
        if (!(max > 0))
            return;
        root.level = current / max;
        root.available = true;
    }

    // One reading at startup, not polling: it decides whether the dashboard has
    // a brightness row at all, so the first open is already the right height
    // instead of growing a row while it animates. shell.qml starts this.
    Component.onCompleted: reader.running = true

    Process {
        id: reader

        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: writer

        onRunningChanged: if (!running) root.flush()
    }

    Timer {
        running: root.watchers > 0
        interval: 1500
        repeat: true
        triggeredOnStart: true
        // A read during a write could hand back the level the write replaces.
        onTriggered: if (!reader.running && !writer.running) reader.running = true
    }
}
