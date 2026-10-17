pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.config

// One of the dashboard's lists, in place of the media and notification cards:
// a header with the way back, the list's name and its on/off switch, then the
// list. It exists only while shown, and keeps the service it is handed
// watched for that long. What a click on a row does is for whatever builds
// on it.
Item {
    id: root

    // The service it shows, kept watched while this exists.
    required property var service
    // What the header's switch shows; clicking it reports switchToggled.
    property bool switchChecked: false
    // Whether the list shows: by default with the switch, since off, a list
    // of networks or devices has nothing left in it.
    property bool listShown: root.switchChecked
    property string title: ""
    property var items: []
    property Component delegate: null
    property string offText: ""
    property string emptyText: ""
    // The item whose details are open, or null: one row at a time.
    property var detailed: null

    signal back()
    signal switchToggled(bool on)

    function toggleDetails(item: var): void {
        root.detailed = root.detailed === item ? null : item;
    }

    // A click on one row closes another row's details.
    function closeDetailsExcept(item: var): void {
        if (root.detailed !== item)
            root.detailed = null;
    }

    implicitWidth: 360
    implicitHeight: 306

    Watch {
        service: root.service
    }

    Surface {
        anchors.fill: parent
    }

    Item {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Spacing.list
        height: 36

        IconButton {
            id: backButton

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            size: 28
            radius: Rounding.small
            background: "transparent"
            glyph: Glyphs.chevronLeft
            label: "back"
            onClicked: root.back()
        }

        Label {
            anchors.left: backButton.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            font.weight: Font.DemiBold
        }

        Switch {
            objectName: "switch"
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            checked: root.switchChecked

            Accessible.name: root.title

            onClicked: root.switchToggled(!root.switchChecked)
        }
    }

    // Keeps a row for each item as the list re-sorts, so the row in use is
    // never rebuilt under the pointer or the keyboard.
    ScriptModel {
        id: rows

        values: root.items
    }

    ListView {
        objectName: "list"
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Spacing.list
        anchors.topMargin: 0
        visible: root.listShown
        clip: true
        spacing: 1
        boundsBehavior: Flickable.StopAtBounds
        model: rows
        delegate: root.delegate
    }

    Subtext {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: header.height / 2
        visible: !root.listShown || root.items.length === 0
        text: root.listShown ? root.emptyText : root.offText
    }
}
