pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What is running and how much of the machine each process uses. Read only
// while watched.
Singleton {
    id: root

    // How many things are showing the processes, each through a Watch.
    property int watchers: 0

    // Each { pid, name, cpu, memory }: cpu is the share of the whole machine
    // over the last interval, 0..1, so the shares add up to the stats line's
    // cpu; memory is resident, in bytes.
    property var processes: []
    // Whether there are shares yet: they are differences, so the first sample
    // has none.
    property bool ready: false

    // CPU time at the last sample, in ticks: the machine's, and each
    // process's by pid.
    property var lastSample: null

    // A resident page, in bytes: 4 KiB on x86-64, which is all this runs on.
    readonly property int pageSize: 4096

    // The heaviest `count`, by "cpu" or "memory". The sort is stable, so ties,
    // most of them idle at 0, keep the order /proc lists them in.
    function top(by: string, count: int): var {
        return root.processes.slice().sort((a, b) => b[by] - a[by]).slice(0, count);
    }

    // Asks a process to quit, or with force, makes it. Only the user's own
    // processes can be signalled; for anyone else's, kill fails and nothing
    // changes.
    function end(pid: int, force: bool): void {
        Quickshell.execDetached(["kill", force ? "-KILL" : "-TERM", String(pid)]);
    }

    // The machine's line from /proc/stat, then one /proc/<pid>/stat line per
    // process: "pid (name) state ...", where the name may hold spaces and
    // parentheses, so the fields are counted from the last ")".
    function parse(text: string): void {
        // A sample that finishes after the last watcher left would undo the reset.
        if (root.watchers === 0)
            return;
        const lines = text.split("\n");
        const machine = lines[0].trim().split(/\s+/).slice(1).map(Number).reduce((a, b) => a + b, 0);
        const before = root.lastSample;
        const elapsed = before ? machine - before.machine : 0;
        const ticks = {};
        const list = [];
        for (const line of lines.slice(1)) {
            const open = line.indexOf("(");
            const close = line.lastIndexOf(")");
            if (open < 0 || close < 0)
                continue;
            const pid = Number(line.slice(0, open));
            // From the state on: utime is the 14th field, stime the 15th,
            // rss the 24th.
            const f = line.slice(close + 2).split(" ");
            const used = Number(f[11]) + Number(f[12]);
            ticks[pid] = used;
            // A process missing from the last sample started since, so all of
            // its time falls in this interval.
            const since = used - (before?.ticks[pid] ?? 0);
            list.push({
                pid,
                name: line.slice(open + 1, close),
                cpu: elapsed > 0 ? since / elapsed : 0,
                memory: Number(f[21]) * root.pageSize
            });
        }
        root.lastSample = {
            machine,
            ticks
        };
        root.processes = list;
        root.ready = elapsed > 0;
    }

    // Shares kept from before a pause would be averages over the whole pause;
    // the list goes too, rather than sit in memory until the pane is next open.
    onWatchersChanged: if (root.watchers === 0) {
        root.lastSample = null;
        root.processes = [];
        root.ready = false;
    }

    // One fork per sample: cat reads every process's stat file, and one that
    // exits between the glob and the read is skipped.
    Process {
        id: sampler

        command: ["sh", "-c", "read -r l < /proc/stat; echo \"$l\"; cat /proc/[0-9]*/stat 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    // The first shares need two samples, so the second comes soon after.
    Timer {
        running: root.watchers > 0
        interval: root.ready ? 2000 : 250
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!sampler.running) sampler.running = true
    }
}
