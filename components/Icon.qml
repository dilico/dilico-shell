import QtQuick
import qs.config

Item {
    id: root

    property string glyph: ""
    property bool active: false
    property color activeColor: Colors.accent
    property color hoverColor: Colors.accent
    property color iconColor: Colors.text
    property real iconSize: Typography.iconSize
    property real padding: 7

    signal clicked()

    implicitWidth: iconSize + padding * 2
    implicitHeight: iconSize + padding * 2

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.active ? Qt.alpha(root.activeColor, 0.18)
             : hover.hovered ? Qt.alpha(root.hoverColor, 0.10)
             : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Animations.durationShort
                easing.type: Animations.easingType
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.family: Typography.fontFamily
        font.pixelSize: root.iconSize
        color: root.active ? root.activeColor
             : hover.hovered ? root.hoverColor
             : root.iconColor

        Behavior on color {
            ColorAnimation {
                duration: Animations.durationShort
                easing.type: Animations.easingType
            }
        }
    }
}