pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int durationMedium: 200
    readonly property int durationShort: 120
    readonly property int easingType: Easing.OutCubic
}
