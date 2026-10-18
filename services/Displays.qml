pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// The monitors plugged in, their modes and where they sit, and setting them:
// live, and in monitors.lua for the next start (conventions §8). Read while
// watched.
Singleton {
    id: root

    // How many things are showing the monitors, each through a Watch.
    property int watchers: 0

    // Each { name, builtIn, model, description, width, height, refresh, x,
    // y, scale, transform, modes }: name is the port, builtIn whether it is a
    // laptop's own panel, the size is the mode's in the monitor's own pixels,
    // x and y are on the layout (see Arrange), and each mode is { width,
    // height, refresh }, the biggest and fastest first.
    property var monitors: []
    // Each monitor's rect on the layout, for drawing them.
    readonly property var layout: Arrange.rects(root.monitors)

    // A new mode on trial: keep() keeps it; revert(), or secondsLeft running
    // out, puts back the monitors as they were before it.
    property var previous: null
    readonly property bool pending: root.previous !== null
    property int secondsLeft: 0

    // Rules for hyprctl eval still to be sent, or "": a change made while the
    // last is being applied waits for it, and only the latest is sent.
    property string queued: ""

    // monitors.lua's rules, as last read or written: the plugged-in monitors'
    // and those of any that are not plugged in now, which a save keeps.
    property var saved: []

    readonly property string path: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/hypr/monitors.lua`

    // Moves one to touch another, as near to (x, y) on the layout as that
    // allows (see Arrange.place).
    function move(name: string, x: real, y: real): void {
        root.set(Arrange.placed(root.monitors, Arrange.place(root.layout, name, x, y)), false);
    }

    // A new size changes where the others fit around it, so they are placed
    // again too.
    function setMode(name: string, mode: var): void {
        const changed = root.monitors.map(m => m.name === name ? Object.assign({}, m, {
                    width: mode.width,
                    height: mode.height,
                    refresh: mode.refresh
                }) : m);
        root.set(Arrange.placed(changed, Arrange.settle(Arrange.rects(changed), name)), true);
    }

    function keep(): void {
        countdown.stop();
        root.previous = null;
        root.save();
    }

    function revert(): void {
        countdown.stop();
        const before = root.previous;
        root.previous = null;
        root.apply(before);
    }

    // Shows and applies a change at once. A trial is saved only once kept; a
    // change made during one joins it, counted from the start again, with the
    // same way back.
    function set(monitors: var, trial: bool): void {
        if (trial && !root.pending)
            root.previous = root.monitors;
        root.apply(monitors);
        if (!root.pending) {
            root.save();
            return;
        }
        root.secondsLeft = 15;
        countdown.restart();
    }

    // Each mode's pixels first, then its rate.
    function biggestFirst(a: var, b: var): int {
        return b.width * b.height - a.width * a.height || b.refresh - a.refresh;
    }

    function apply(monitors: var): void {
        root.monitors = monitors;
        root.queued = monitors.map(m => MonitorRules.call(MonitorRules.rule(m))).join("\n");
        if (!applier.running)
            root.flush();
    }

    function flush(): void {
        applier.command = ["hyprctl", "eval", root.queued];
        root.queued = "";
        applier.running = true;
    }

    function save(): void {
        root.saved = MonitorRules.merge(root.saved, root.monitors.map(MonitorRules.rule));
        file.setText(MonitorRules.file(root.saved));
    }

    function refresh(): void {
        reader.running = true;
    }

    // hyprctl's JSON, the disabled ones left out: nothing here turns one on.
    // A laptop's own panel is on an eDP, LVDS or DSI connector.
    function read(text: string): void {
        let list;
        try {
            list = JSON.parse(text);
        } catch (e) {
            return;
        }
        root.monitors = list.filter(m => !m.disabled).map(m => ({
                    name: m.name,
                    builtIn: /^(eDP|LVDS|DSI)-/.test(m.name),
                    model: m.model,
                    description: m.description,
                    width: m.width,
                    height: m.height,
                    refresh: m.refreshRate,
                    x: m.x,
                    y: m.y,
                    scale: m.scale,
                    transform: m.transform,
                    modes: m.availableModes.map(MonitorRules.mode).filter(Boolean).sort(root.biggestFirst)
                }));
    }

    onWatchersChanged: {
        if (root.watchers > 0)
            root.refresh();
    }

    // A monitor plugged in or out.
    Connections {
        target: Quickshell

        function onScreensChanged(): void {
            if (root.watchers > 0)
                root.refresh();
        }
    }

    Process {
        id: reader

        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: root.read(text)
        }
    }

    // Read again once applied, for what Hyprland made of it.
    Process {
        id: applier

        onRunningChanged: {
            if (applier.running)
                return;
            if (root.queued !== "")
                root.flush();
            else
                root.refresh();
        }
    }

    Timer {
        id: countdown

        interval: 1000
        repeat: true
        onTriggered: {
            root.secondsLeft--;
            if (root.secondsLeft <= 0)
                root.revert();
        }
    }

    // A missing file is no saved rules.
    FileView {
        id: file

        path: root.path
        onLoaded: root.saved = MonitorRules.parse(file.text())
    }
}
