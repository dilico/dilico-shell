pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property color background: "#21252D"
    readonly property color surface: "#343d46"
    readonly property color text: "#fff"
    readonly property color textDim: "#65737e"
    readonly property color accent: "#98C379" // 7EE787
    readonly property color border: Qt.rgba(1, 1, 1, 0.15)
}
