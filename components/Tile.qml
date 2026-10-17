import QtQuick
import qs.config

// A toggle with a title and its state. Given a `detailLabel`, a chevron at the
// right edge opens more.
Item {
    id: root

    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    // What the chevron opens, for assistive tech; none, no chevron.
    property string detailLabel: ""

    readonly property bool hasDetail: root.detailLabel !== ""

    signal clicked()
    signal detailClicked()

    implicitWidth: 170
    implicitHeight: 56

    Surface {
        anchors.fill: parent
        active: root.active
        hovered: toggle.hovered || detail.hovered
    }

    Pressable {
        id: toggle

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: root.hasDetail ? detail.left : parent.right

        Accessible.role: Accessible.CheckBox
        Accessible.name: root.title
        Accessible.checkable: true
        Accessible.checked: root.active

        onClicked: root.clicked()

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
            anchors.rightMargin: root.hasDetail ? 0 : 10
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

    ChevronButton {
        id: detail

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: root.hasDetail
        color: root.active ? Colors.activeText : Colors.text

        Accessible.name: root.detailLabel

        onClicked: root.detailClicked()
    }
}
