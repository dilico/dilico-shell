pragma Singleton

import Quickshell
import Quickshell.Io

// Whether the screen is kept awake: while it is, the idle inhibitor in
// shell.qml stops hypridle's timers. Kept across restarts.
Singleton {
    id: root

    property bool inhibited: false

    function toggle(): void {
        root.inhibited = !root.inhibited;
        store.setText(JSON.stringify({
            inhibited: root.inhibited
        }));
    }

    // A file that is missing or unreadable starts it off. Missing is normal
    // until the first toggle, so it is not reported.
    FileView {
        id: store

        path: Quickshell.statePath("idle.json")
        printErrors: false
        onLoaded: {
            try {
                root.inhibited = JSON.parse(store.text()).inhibited === true;
            } catch (e) {
                root.inhibited = false;
            }
        }
    }
}
