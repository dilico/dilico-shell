pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    // One size per role. Text picks a role through its component — Label for
    // body, Subtext, Caption — rather than a size from here.
    readonly property int clockSize: 52
    readonly property int bodySize: 13
    readonly property int subtextSize: 12
    readonly property int captionSize: 11
    readonly property int iconSize: 16
}
