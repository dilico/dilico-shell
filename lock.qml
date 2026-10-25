pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.modules.lock
import qs.services

// The lock screen, as its own instance (conventions §2): hypridle's lock_cmd
// starts it with `qs -p ~/.config/quickshell/dilico/lock.qml -n -d`, and
// unlocking ends it. While it runs, Hyprland shows nothing but its surfaces,
// one per screen, and no window takes input.
ShellRoot {
    id: root

    // DILICO_LOCK_PREVIEW=1 shows the lock screen in an ordinary window
    // instead of locking: for working on how it looks, never for locking.
    // `qs kill -p` closes it.
    readonly property bool preview: Quickshell.env("DILICO_LOCK_PREVIEW") === "1"

    // A reload replaces every object, the lock among them; a lock screen
    // that blinks out while files are saved is not one.
    settings.watchFiles: false

    // Seconds, though it shows minutes: the lock is up through sleep, and a
    // minute clock wakes showing the minute it fell asleep in (see services/Clock).
    // The lock is what shows on waking, so it ticks each second rather than
    // waiting to hear of it; it only runs while locked.
    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    WlSessionLock {
        id: lock

        locked: !root.preview

        WlSessionLockSurface {
            color: Colors.lockGround

            Face {}
        }
    }

    Connections {
        target: Auth

        function onSucceeded(): void {
            lock.locked = false;
            quitTimer.start();
        }
    }

    // Exits a moment after unlocking rather than at once, so the unlock
    // reaches Hyprland before the connection closes. A locker that exits
    // still holding the lock leaves the session locked, with nothing to type
    // into.
    Timer {
        id: quitTimer

        interval: 500
        onTriggered: Qt.quit()
    }

    LazyLoader {
        active: root.preview

        // qmllint disable uncreatable-type
        // False positive, as in shell.qml: PanelWindow is creatable.
        PanelWindow {
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.namespace: "quickshell:dilico-lock-preview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusiveZone: -1
            color: Colors.lockGround

            Face {}
        }
    }

    // The same on a lock surface and in the preview.
    component Face: LockScreen {
        anchors.fill: parent
        date: clock.date
    }
}
