import QtQuick
import qs.config

Item {
    id: root

    // 0..1. Displayed, never written: the owner turns moved() into a value.
    property real value: 0
    property bool dimmed: false
    // The ring around the knob is the colour of what the slider sits on, so
    // the knob reads as cut out of the track rather than pasted over it.
    property color ringColor: Colors.island

    readonly property real knobSize: 16
    readonly property real trackHeight: 4
    // One wheel notch in angleDelta units, and how far a notch moves the value.
    readonly property real notch: 120
    readonly property real step: 0.05

    readonly property real position: Math.max(0, Math.min(1, root.value))
    readonly property color fillColor: root.dimmed ? Colors.textFaint : Colors.text

    signal moved(real value)

    function emitAt(x: real): void {
        const span = root.width - root.knobSize;
        const p = span <= 0 ? 0 : Math.max(0, Math.min(1, (x - root.knobSize / 2) / span));
        root.moved(p);
    }

    function nudge(delta: real): void {
        root.moved(Math.max(0, Math.min(1, root.position + delta)));
    }

    implicitWidth: 160
    implicitHeight: 28

    Accessible.role: Accessible.Slider
    Accessible.onIncreaseAction: root.nudge(root.step)
    Accessible.onDecreaseAction: root.nudge(-root.step)

    Track {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        value: root.position
        inset: root.knobSize / 2
        fillColor: root.fillColor
    }

    Rectangle {
        x: (root.width - root.knobSize) * root.position
        anchors.verticalCenter: parent.verticalCenter
        width: root.knobSize
        height: root.knobSize
        radius: Rounding.small
        color: root.fillColor
        border.width: 3
        border.color: root.ringColor
    }

    MouseArea {
        id: area

        // Wheel travel not yet worth a step. A touchpad or a smooth wheel
        // sends many small deltas where a plain wheel sends one notch, so the
        // value moves per notch of travel, never per event.
        property real pending: 0

        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        onPressed: event => root.emitAt(event.x)
        onPositionChanged: event => {
            if (pressed)
                root.emitAt(event.x);
        }
        onWheel: event => {
            const dy = event.angleDelta.y;
            // Sideways scrolling says nothing about this slider.
            if (dy === 0)
                return;
            // Turning back starts afresh rather than first unwinding the rest.
            if (Math.sign(dy) !== Math.sign(area.pending))
                area.pending = 0;
            area.pending += dy;
            const notches = Math.trunc(area.pending / root.notch);
            if (notches === 0)
                return;
            area.pending -= notches * root.notch;
            root.nudge(notches * root.step);
        }
    }
}
