pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// What the shell reads from Hyprland, and the keys Hyprland hands it.
Singleton {
    id: root

    // Which workspace is focused, as a number that changes when it does.
    readonly property int focusedWorkspace: Hyprland.focusedWorkspace?.id ?? 0

    // The launcher key, bound in hyprland.lua to
    // hl.dsp.global("quickshell:launcher").
    signal launcherPressed()

    // Whether this is the screen the user is on.
    function focused(screen: ShellScreen): bool {
        return Hyprland.focusedMonitor?.name === screen?.name;
    }

    // qmllint disable import unresolved-type
    // False positive: Quickshell's _GlobalShortcuts module does not declare
    // that it depends on Quickshell, so qmllint cannot find PostReloadHook,
    // the type GlobalShortcut builds on. Quickshell itself loads it. The
    // import warning is reported past the end of the file, so that rule stays
    // off to the end; this is the last thing in it.
    GlobalShortcut {
        name: "launcher"
        description: "Open the app launcher"
        onPressed: root.launcherPressed()
    }
    // qmllint enable unresolved-type
}
