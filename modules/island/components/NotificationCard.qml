pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services
import qs.utils

Item {
    id: root

    // How far the list sits in from the card's edge. A row's hover ground
    // fills that inset; its text steps back in to the card's padding, so it
    // lines up with the header and the media card above.
    readonly property int listInset: 6

    function timeOf(notification: var): string {
        const t = Notifications.arrivedAt(notification);
        return t > 0 ? Format.time(new Date(t)) : "";
    }

    implicitWidth: 360
    // The least it needs; the dashboard stretches it to fill what the media
    // card leaves.
    implicitHeight: 100

    Surface {
        anchors.fill: parent
    }

    Subtext {
        id: header

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: Spacing.card
        anchors.topMargin: 10
        text: "notifications"
    }

    Pressable {
        id: clear

        anchors.right: parent.right
        anchors.rightMargin: Spacing.card
        anchors.verticalCenter: header.verticalCenter
        implicitWidth: clearText.implicitWidth
        implicitHeight: clearText.implicitHeight
        visible: Notifications.count > 0

        Accessible.name: "clear notifications"

        onClicked: Notifications.clear()

        Subtext {
            id: clearText

            text: "clear"
            color: clear.hovered ? Colors.text : Colors.textDim
        }
    }

    ListView {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.listInset
        anchors.topMargin: 6
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: Notifications.list

        delegate: Pressable {
            id: entry

            required property var modelData

            width: ListView.view.width
            height: 46

            Accessible.name: `dismiss: ${entry.modelData.summary}`

            // Clicking a notification dismisses it; there are no actions yet.
            onClicked: entry.modelData.dismiss()

            Surface {
                anchors.fill: parent
                radius: Rounding.small
                hovered: entry.hovered
                restColor: "transparent"
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: Spacing.card - root.listInset
                anchors.right: time.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Label {
                    width: parent.width
                    text: entry.modelData.summary || entry.modelData.appName
                    elide: Text.ElideRight
                    font.weight: Font.Medium
                }

                Subtext {
                    width: parent.width
                    text: entry.modelData.body || entry.modelData.appName
                    textFormat: Text.PlainText
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }
            }

            Caption {
                id: time

                anchors.right: parent.right
                anchors.rightMargin: Spacing.card - root.listInset
                anchors.top: parent.top
                anchors.topMargin: 8
                text: root.timeOf(entry.modelData)
            }
        }
    }

    Subtext {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 10
        visible: Notifications.count === 0
        text: "no notifications"
    }
}
