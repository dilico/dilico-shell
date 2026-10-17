import QtQuick
import qs.config

// A chevron that opens more. It goes beside whatever it belongs to rather than
// inside it, so one tap never does both. Points down while open.
Pressable {
    id: root

    property bool open: false
    property color color: root.hovered ? Colors.text : Colors.textDim

    implicitWidth: 28

    Label {
        anchors.centerIn: parent
        rotation: root.open ? 90 : 0
        text: Glyphs.chevronRight
        color: root.color
    }
}
