import QtQuick
import qs.config

// The ground under a control or a card: inverted while active, lighter while
// hovered, and fading between the three. A card leaves both false.
Rectangle {
    id: root

    property bool active: false
    property bool hovered: false
    property color restColor: Colors.surface
    property color activeColor: Colors.activeBackground

    radius: Rounding.control
    color: root.active ? root.activeColor
        : root.hovered ? Colors.surfaceHover
        : root.restColor

    Behavior on color {
        ColorAnimation {
            duration: Animations.durationShort
            easing.type: Animations.easingType
        }
    }
}
