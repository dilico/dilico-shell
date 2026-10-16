pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int durationShort: 120
    readonly property int durationMedium: 200
    // The pill growing into the dashboard: long enough to read as one object
    // changing shape rather than one thing swapped for another.
    readonly property int durationLong: 320
    readonly property int easingType: Easing.OutCubic
}
