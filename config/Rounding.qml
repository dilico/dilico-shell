pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // `rounding` in hyprland.lua, so the island and the windows under it share
    // one corner.
    readonly property int window: 10

    // Controls and cards inside the island. Inset from its corner, so they
    // round less than it does.
    readonly property int control: 6

    // Parts inside a control: album art, list rows, segment highlights, knobs.
    readonly property int small: 4
}
