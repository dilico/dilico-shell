pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// The wifi list, in place of the media and notification cards. It exists only
// while shown, which keeps the radio scanning only then, and it decides what a
// click on a network does: one row has something open at a time.
Item {
    id: root

    // The saved network whose details are open, or null.
    property var detailed: null

    signal back()

    // A click on a row: the connected network opens its details, an open
    // prompt closes, anything else is joined.
    function activate(network: var, expanded: bool): void {
        if (network?.connected) {
            root.toggleDetails(network);
            return;
        }
        root.collapseExcept(network);
        if (expanded)
            Network.cancel();
        else
            Network.join(network);
    }

    function toggleDetails(network: var): void {
        root.collapseExcept(network);
        root.detailed = root.detailed === network ? null : network;
    }

    // Whatever another row has open collapses: its details, or its prompt.
    function collapseExcept(network: var): void {
        if (root.detailed !== network)
            root.detailed = null;
        if (Network.joining && Network.joining !== network)
            Network.abandon();
    }

    implicitWidth: 360
    implicitHeight: 306

    // Opens clean, and leaves nothing behind but a password already sent.
    Component.onCompleted: Network.abandon()
    Component.onDestruction: Network.abandon()

    Watch {
        service: Network
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
            text: "network"
            font.weight: Font.DemiBold
        }

        Switch {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            checked: Network.enabled

            Accessible.name: "wi-fi"

            onClicked: Network.setEnabled(!Network.enabled)
        }
    }

    // Keeps a row for each network as the list re-sorts, so the row in use is
    // never rebuilt under the pointer or the keyboard.
    ScriptModel {
        id: rows

        values: Network.networks
    }

    ListView {
        objectName: "networks"
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Spacing.list
        anchors.topMargin: 0
        visible: Network.enabled
        clip: true
        spacing: 1
        boundsBehavior: Flickable.StopAtBounds
        model: rows

        delegate: NetworkRow {
            id: row

            required property var modelData

            width: ListView.view.width
            network: row.modelData
            // A forgotten network has no details left to show.
            detailsOpen: root.detailed === row.modelData && row.known
            onClicked: root.activate(row.modelData, row.expanded)
            onDetailsToggled: root.toggleDetails(row.modelData)
        }
    }

    Subtext {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: header.height / 2
        visible: !Network.enabled || Network.networks.length === 0
        text: !Network.enabled ? "wi-fi is off" : "looking for networks"
    }
}
