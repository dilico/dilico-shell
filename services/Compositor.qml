pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// What the shell reads from Hyprland.
Singleton {
    id: root

    // Whether this is the screen the user is on.
    function focused(screen: ShellScreen): bool {
        return Hyprland.focusedMonitor?.name === screen?.name;
    }
}
