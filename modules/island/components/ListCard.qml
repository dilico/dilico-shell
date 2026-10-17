pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components

// One of the dashboard's lists: a pane whose header has the list's on/off
// switch, then the list. It exists only while shown, and keeps the service it is handed
// watched for that long. What a click on a row does is for whatever builds
// on it.
PaneCard {
    id: root

    // The service it shows, kept watched while this exists.
    required property var service
    // What the header's switch shows; clicking it reports switchToggled.
    property bool switchChecked: false
    // Whether the list shows: by default with the switch, since off, a list
    // of networks or devices has nothing left in it.
    property bool listShown: root.switchChecked
    property var items: []
    property Component delegate: null
    property string offText: ""
    property string emptyText: ""
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

    trailing: Switch {
        objectName: "switch"
        anchors.verticalCenter: parent.verticalCenter
        checked: root.switchChecked

        Accessible.name: root.title

        onClicked: root.switchToggled(!root.switchChecked)
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

    ListView {
        objectName: "list"
        anchors.fill: parent
        visible: root.listShown
        clip: true
        spacing: 1
        boundsBehavior: Flickable.StopAtBounds
        model: rows
        delegate: root.delegate
    }

    Subtext {
        anchors.centerIn: parent
        visible: !root.listShown || root.items.length === 0
        text: root.listShown ? root.emptyText : root.offText
    }
}
