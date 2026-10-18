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

    // The lock screen's clock, date and password prompt, set directly as one
    // composition, like clockSize.
    readonly property int lockClockSize: 200
    readonly property int lockDateSize: 18
    readonly property int lockPromptSize: 18
}
