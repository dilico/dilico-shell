import QtQuick
import qs.config

// A bar filled from the left: the groove under a slider, a progress line.
Rectangle {
    id: root

    // 0..1
    property real value: 0
    // How far in from each end 0 and 1 sit. A slider's knob centre cannot
    // reach the ends, so its fill stops where the knob does.
    property real inset: 0
    property color fillColor: Colors.text

    radius: root.height / 2
    color: Colors.track

    Rectangle {
        width: root.inset + (root.width - root.inset * 2) * Math.max(0, Math.min(1, root.value))
        height: root.height
        radius: root.radius
        color: root.fillColor
    }
}
