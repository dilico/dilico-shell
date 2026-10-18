pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Black and greys only. The island is pure black so it reads as part of the
    // screen edge it hangs from; everything inside steps up from there.
    readonly property color island: "#000000"
    readonly property color surface: "#141414"
    readonly property color surfaceHover: "#1c1c1c"
    readonly property color surfaceRaised: "#2a2a2a"
    readonly property color divider: "#1c1c1c"
    // Around the island, so it stays distinct from a black window under it.
    readonly property color outline: "#383838"
    readonly property color track: "#262626"

    readonly property color text: "#e8e8e8"
    readonly property color textMid: "#bdbdbd"
    readonly property color textDim: "#8c8c8c"
    readonly property color textFaint: "#4a4a4a"

    // An active control inverts: light ground, dark ink.
    readonly property color activeBackground: "#e8e8e8"
    readonly property color activeText: "#0a0a0a"
    readonly property color activeSubtext: "#4a4a4a"

    readonly property color backdrop: Qt.rgba(0, 0, 0, 0.45)

    // The lock screen: dark frost, opaque, so nothing behind it shows. The
    // glow is the lighter corner the frost fades out from. Its text is the
    // shell's own, the way the terminal's prompt is coloured.
    readonly property color lockGround: "#1e2023"
    readonly property color lockGlow: "#2d3034"
}
