pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // How many things are showing the numbers, each through a Watch; nothing
    // is read while there are none.
    property int watchers: 0

    // 0..1, or -1 until two samples exist to take a difference between.
    property real cpu: -1
    // GiB
    property real memUsed: 0
    property real memTotal: 0
    // °C, or -1 while unknown.
    property real temperature: -1

    property var lastCpu: null

    readonly property string script: [
        "read -r line < /proc/stat; echo \"$line\"",
        "while read -r k v _; do case $k in MemTotal:|MemAvailable:) echo \"$k $v\";; esac; done < /proc/meminfo",
        "for z in /sys/class/thermal/thermal_zone*; do read -r t < \"$z/type\"; [ \"$t\" = x86_pkg_temp ] && read -r v < \"$z/temp\" && echo \"temp $v\" && break; done"
    ].join("; ")

    function parse(text: string): void {
        // A sample that finishes after the last watcher left would undo the reset.
        if (root.watchers === 0)
            return;
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            if (f[0] === "cpu") {
                const n = f.slice(1).map(Number);
                const idle = n[3] + (n[4] || 0);
                const total = n.reduce((a, b) => a + b, 0);
                if (root.lastCpu) {
                    const dt = total - root.lastCpu.total;
                    if (dt > 0)
                        root.cpu = 1 - (idle - root.lastCpu.idle) / dt;
                }
                root.lastCpu = {
                    idle,
                    total
                };
            } else if (f[0] === "MemTotal:") {
                root.memTotal = Number(f[1]) / 1048576;
            } else if (f[0] === "MemAvailable:") {
                root.memUsed = root.memTotal - Number(f[1]) / 1048576;
            } else if (f[0] === "temp") {
                root.temperature = Number(f[1]) / 1000;
            }
        }
    }

    // A sample kept from before a pause would make the first reading after it
    // the average over the whole pause, so the difference starts afresh.
    onWatchersChanged: if (root.watchers === 0) {
        root.lastCpu = null;
        root.cpu = -1;
    }

    // One process per sample, reading only with shell builtins, so a sample
    // forks once rather than once per file. The CPU package sensor is found by
    // type because thermal_zone numbering is not stable across kernels or boots.
    Process {
        id: sampler

        command: ["sh", "-c", root.script]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    // The first reading needs two samples, so the second comes soon after.
    Timer {
        running: root.watchers > 0
        interval: root.cpu < 0 ? 250 : 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!sampler.running) sampler.running = true
    }
}
