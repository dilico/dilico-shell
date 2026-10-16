pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // How the island meets the top edge.
    //   true  — a notch: hangs from the edge, flaring into it with a concave
    //           fillet on each side.
    //   false — a pill: floats `gap` below the edge, rounded all round.
    readonly property bool attached: false

    // The pill's distance from the top edge: `gaps_out` in hyprland.lua, so it
    // sits as far from the edge as the windows do.
    readonly property int gap: 4
}
