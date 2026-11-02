import QtQuick
import qs.components
import qs.config

// What stands in for the media and notification cards: a card with a header
// that has the way back, the pane's name and whatever controls the pane puts
// at its right, and below it the pane itself.
Item {
    id: root

    property string title: ""
    // The pane's contents, filling the card under the header.
    default property alias body: bodyItem.data
    // The header's controls at the right edge, in order.
    property alias trailing: trailingRow.data

    // The header's height, and how far in from the right its controls sit,
    // for a heading in the body to line up with.
    readonly property int headerHeight: 36
    readonly property int trailingInset: 4

    signal back()

    implicitWidth: 360
    implicitHeight: 306

    Surface {
        anchors.fill: parent
    }

    Item {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Spacing.list
        height: root.headerHeight

        HeaderButton {
            id: backButton

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            glyph: Glyphs.chevronLeft
            label: "back"
            onClicked: root.back()
        }

        Label {
            objectName: "title"

            anchors.left: backButton.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            font.weight: Font.DemiBold
        }

        Row {
            id: trailingRow

            anchors.right: parent.right
            anchors.rightMargin: root.trailingInset
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
        }
    }

    Item {
        id: bodyItem

        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Spacing.list
        anchors.topMargin: 0
    }
}
