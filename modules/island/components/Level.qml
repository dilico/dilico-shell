import QtQuick
import qs.components
import qs.config
import qs.utils

// A level as the pill shows it for a moment after it changes, the volume or
// the brightness: the glyph, how full, and the number. Shown, never touched;
// the dashboard's sliders are what change them.
Row {
    id: root

    property string glyph
    // 0..1
    property real value: 0
    property bool muted: false

    spacing: 10

    // A box of its own: the volume's glyphs for low, high and muted differ in
    // width, and the pill would twitch as the volume crossed between them.
    Label {
        anchors.verticalCenter: parent.verticalCenter
        width: Typography.iconSize
        horizontalAlignment: Text.AlignHCenter
        text: root.glyph
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
