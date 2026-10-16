import QtQuick
import qs.config

// Not interactive, it is a plain glyph in a button's place: no hover, no click.
Pressable {
    id: root

    property string glyph: ""
    // What the button does, for assistive tech; the glyph alone says nothing.
    property string label: ""
    // Inverted, the way an active tile is. The owner decides what that means.
    property bool highlighted: false
    property real size: 34
    property real radius: Rounding.control
    property color background: Colors.surface
    property color iconColor: Colors.textMid

    implicitWidth: root.size
    implicitHeight: root.size

    Accessible.role: root.interactive ? Accessible.Button : Accessible.Graphic
    Accessible.name: root.label

    Surface {
        anchors.fill: parent
        radius: root.radius
        active: root.highlighted
        hovered: root.hovered
        restColor: root.background
    }

    Label {
        anchors.centerIn: parent
        text: root.glyph
        color: root.highlighted ? Colors.activeText : root.iconColor
        font.pixelSize: Typography.iconSize
    }
}
