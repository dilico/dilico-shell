import QtQuick
import qs.config

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real trackHeight: 4
    property real handleSize: 12
    property color trackColor: Qt.alpha(Colors.text, 0.15)
    property color fillColor: Colors.accent

    readonly property bool pressed: mouseArea.pressed
    readonly property real position: to === from
        ? 0 : Math.max(0, Math.min(1, (value - from) / (to - from)))

    signal moved(real value)

    function emitAt(x: real): void {
        const span = root.width - root.handleSize;
        const p = span <= 0 ? 0
            : Math.max(0, Math.min(1, (x - root.handleSize / 2) / span));
        root.moved(root.from + p * (root.to - root.from));
    }

    implicitWidth: 120
    implicitHeight: Math.max(handleSize, trackHeight)

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: height / 2
        color: root.trackColor

        Rectangle {
            width: parent.width * root.position
            height: parent.height
            radius: parent.radius
            color: root.fillColor
        }
    }

    Rectangle {
        x: (root.width - root.handleSize) * root.position
        anchors.verticalCenter: parent.verticalCenter
        width: root.handleSize
        height: root.handleSize
        radius: height / 2
        color: root.fillColor
        scale: mouseArea.pressed ? 1.2 : mouseArea.containsMouse ? 1.1 : 1

        Behavior on scale {
            NumberAnimation {
                duration: Animations.durationShort
                easing.type: Animations.easingType
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        onPressed: event => root.emitAt(event.x)
        onPositionChanged: event => {
            if (pressed)
                root.emitAt(event.x);
        }
    }
}
