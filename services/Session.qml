pragma Singleton

import Quickshell

Singleton {
    id: root

    // hypridle's lock_cmd answers lock-session, so locking goes through the same
    // path as the idle timer and never starts a second hyprlock.
    function lock(): void {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    // The same command as the SUPER+M binding in hyprland.lua.
    function logout(): void {
        Quickshell.execDetached(["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"]);
    }

    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function poweroff(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
