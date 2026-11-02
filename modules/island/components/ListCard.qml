pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components

// One of the dashboard's lists: a pane whose header has the list's on/off
// switch (or the list's own heading has it; see listTitle), then the list. It
// exists only while shown, and keeps the service it is handed watched for
// that long. What a click on a row does is for whatever builds on it.
PaneCard {
    id: root

    // The service it shows, kept watched while this exists.
    required property var service
    // What the switch shows; clicking it reports switchToggled.
    property bool switchChecked: false
    // Whether the list shows: by default with the switch, since off, a list
    // of networks or devices has nothing left in it.
    property bool listShown: root.switchChecked
    property var items: []
    property Component delegate: null
    property string offText: ""
    property string emptyText: ""
    // For a pane that shows more than the list: the list's own heading,
    // which takes the switch from the pane's header, so the switch is plainly
    // the list's alone.
    property string listTitle: ""
    // What sits above the list and its heading, or null.
    property alias above: aboveLoader.sourceComponent
    // The item whose details are open, or null: one row at a time.
    property var detailed: null

    signal switchToggled(bool on)

    function toggleDetails(item: var): void {
        root.detailed = root.detailed === item ? null : item;
    }

    // A click on one row closes another row's details.
    function closeDetailsExcept(item: var): void {
        if (root.detailed !== item)
            root.detailed = null;
    }

    trailing: Item {
        id: trailingSlot

        width: childrenRect.width
        height: childrenRect.height
    }

    Watch {
        service: root.service
    }

    // Keeps a row for each item as the list re-sorts, so the row in use is
    // never rebuilt under the pointer or the keyboard.
    ScriptModel {
        id: rows

        values: root.items
    }

    Column {
        id: lead

        width: parent.width
        spacing: 1

        Loader {
            id: aboveLoader

            width: parent.width
            visible: aboveLoader.item !== null
        }

        Item {
            width: parent.width
            height: root.headerHeight
            visible: root.listTitle !== ""

            Caption {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.listTitle
            }

            Item {
                id: headingSlot

                anchors.right: parent.right
                anchors.rightMargin: root.trailingInset
                anchors.verticalCenter: parent.verticalCenter
                width: childrenRect.width
                height: childrenRect.height
            }
        }
    }

    ListView {
        id: list

        objectName: "list"
        anchors.fill: parent
        anchors.topMargin: lead.height
        visible: root.listShown
        clip: true
        spacing: 1
        boundsBehavior: Flickable.StopAtBounds
        model: rows
        delegate: root.delegate
    }

    Subtext {
        anchors.centerIn: list
        visible: !root.listShown || root.items.length === 0
        text: root.listShown ? root.emptyText : root.offText
    }

    Switch {
        objectName: "switch"
        parent: root.listTitle === "" ? trailingSlot : headingSlot
        checked: root.switchChecked

        Accessible.name: root.listTitle || root.title

        onClicked: root.switchToggled(!root.switchChecked)
    }
}
