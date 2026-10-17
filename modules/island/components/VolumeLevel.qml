import QtQuick
import qs.components
import qs.config
import qs.utils

// The volume as the pill shows it for a moment after it changes: the glyph,
// how full, and the number. Shown, never touched; the dashboard's slider is
// what changes it.
Row {
    id: root

    // 0..1
    property real value: 0
    property bool muted: false

    spacing: 10

    // A box of its own: the glyphs for low, high and muted differ in width,
    // and the pill would twitch as the volume crossed between them.
    Label {
        anchors.verticalCenter: parent.verticalCenter
        width: Typography.iconSize
        horizontalAlignment: Text.AlignHCenter
        text: Icons.volume(root.muted, root.value)
        color: root.muted ? Colors.textDim : Colors.text
        font.pixelSize: Typography.iconSize
    }

    Track {
        anchors.verticalCenter: parent.verticalCenter
        width: 120
        height: 4
        value: root.value
        fillColor: root.muted ? Colors.textFaint : Colors.text
    }

    Caption {
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        horizontalAlignment: Text.AlignRight
        text: Format.percentOrOff(root.muted, root.value)
    }
}
