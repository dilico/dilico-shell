pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

// qmllint disable import
// False positive, for the whole file: Quickshell's _GlobalShortcuts module
// does not declare that it depends on Quickshell, so qmllint cannot find
// PostReloadHook, the type GlobalShortcut builds on. Quickshell itself loads
// it. The warning is placed at line 35 whatever this file holds, the line
// GlobalShortcut is declared on in Quickshell's source, so no narrower range
// is sure to cover it.

// What the shell reads from Hyprland, and the keys Hyprland hands it.
Singleton {
    id: root

    // Which workspace is focused, as a number that changes when it does.
    readonly property int focusedWorkspace: Hyprland.focusedWorkspace?.id ?? 0

    // The launcher key, bound in hyprland.lua to
    // hl.dsp.global("quickshell:launcher").
    signal launcherPressed()

    // A screen changed its own workspace, named by the screen. Not when
    // Hyprland first reports, nor when focus moves to another screen.
    signal workspaceSwitched(string screen)

    // Whether this is the screen the user is on.
    function focused(screen: ShellScreen): bool {
        return Hyprland.focusedMonitor?.name === screen?.name;
    }

    // The workspace a screen is showing, as the number of its key, or 0 until
    // Hyprland has reported. A screen's own change only: focus moving to
    // another screen changes the focused workspace but not this.
    function workspaceOn(screen: ShellScreen): int {
        return root.number(Hyprland.monitorFor(screen)?.activeWorkspace?.id ?? 0);
    }

    // The workspaces a screen has, in order: those with windows, and the one
    // it is showing, which Hyprland keeps while it is empty.
    // [{ number: int, current: bool }]
    function workspacesOn(screen: ShellScreen): var {
        const monitor = Hyprland.monitorFor(screen);
        const current = monitor?.activeWorkspace?.id ?? 0;
        return Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === monitor).sort((a, b) => a.id - b.id).map(w => ({
                    number: root.number(w.id),
                    current: w.id === current
                }));
    }

    // hyprland.lua gives each screen ten workspaces, 1–10 and 11–20, both
    // reached with Super and 1 to 0, so a screen's are numbered 1–10 there.
    // Special workspaces have ids below 0 and no number.
    function number(id: int): int {
        return id > 0 ? (id - 1) % 10 + 1 : 0;
    }

    // One watcher per monitor, since a switch is a change of a monitor's own
    // workspace. Each keeps the last one Hyprland reported, so the first
    // report, and a moment with none, are not switches.
    Instantiator {
        model: Hyprland.monitors

        delegate: Connections {
            id: watcher

            // A HyprlandMonitor.
            required property var modelData
            property int last: 0

            function onActiveWorkspaceChanged(): void {
                const id = watcher.modelData.activeWorkspace?.id ?? 0;
                if (id <= 0)
                    return;
                if (watcher.last > 0 && id !== watcher.last)
                    root.workspaceSwitched(watcher.modelData.name);
                watcher.last = id;
            }

            target: watcher.modelData
            Component.onCompleted: watcher.last = watcher.modelData.activeWorkspace?.id ?? 0
        }
    }

    // qmllint disable unresolved-type
    // The same false positive: without PostReloadHook, GlobalShortcut's type
    // is unresolved too.
    GlobalShortcut {
        name: "launcher"
        description: "Open the app launcher"
        onPressed: root.launcherPressed()
    }
    // qmllint enable unresolved-type
}
