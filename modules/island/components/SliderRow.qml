import QtQuick
import qs.components
import qs.config
import qs.utils

Item {
    id: root

    property string glyph: ""
    property string label: ""
    // 0..1
    property real value: 0
    property bool muted: false
    // Whether the icon is a mute button. Brightness has nothing to mute.
    property bool toggleable: true

    signal moved(real value)
    signal toggled()

    // What the icon says it does, for assistive tech.
    function buttonLabel(): string {
        if (!root.toggleable)
            return root.label;
        return `${root.muted ? "unmute" : "mute"} ${root.label}`;
    }

    implicitWidth: 300
    implicitHeight: button.implicitHeight

    IconButton {
        id: button

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        interactive: root.toggleable
        glyph: root.glyph
        label: root.buttonLabel()
        iconColor: root.muted ? Colors.textDim : Colors.text
        onClicked: root.toggled()
    }

    Slider {
        anchors.left: button.right
        anchors.leftMargin: 12
        anchors.right: valueText.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        value: root.value
        dimmed: root.muted
        Accessible.name: root.label
        onMoved: v => root.moved(v)
    }

    Caption {
        id: valueText

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        horizontalAlignment: Text.AlignRight
        text: root.muted ? "off" : Format.percent(root.value)
    }
}
