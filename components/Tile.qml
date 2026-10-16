import QtQuick
import qs.config

Pressable {
    id: root

    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false

    implicitWidth: 170
    implicitHeight: 56

    Accessible.role: Accessible.CheckBox
    Accessible.name: root.title
    Accessible.checked: root.active
    Accessible.onToggleAction: root.clicked()

    Surface {
        anchors.fill: parent
        active: root.active
        hovered: root.hovered
    }

    Label {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        color: root.active ? Colors.activeText : Colors.text
        font.pixelSize: Typography.iconSize
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Label {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            color: root.active ? Colors.activeText : Colors.text
            font.weight: Font.DemiBold
        }

        Caption {
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            color: root.active ? Colors.activeSubtext : Colors.textDim
        }
    }
}
