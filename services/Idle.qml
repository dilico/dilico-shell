pragma Singleton

import Quickshell

Singleton {
    id: root

    property bool inhibited: false

    function toggle(): void {
        root.inhibited = !root.inhibited;
    }
}
