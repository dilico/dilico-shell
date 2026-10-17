pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// The wifi list. It decides what a click on a network does: one row has
// something open at a time.
ListCard {
    id: root

    // A click on a row: the connected network opens its details, an open
    // prompt closes, anything else is joined.
    function activate(network: var, expanded: bool): void {
        if (network?.connected) {
            root.openDetails(network);
            return;
        }
        root.collapseExcept(network);
        if (expanded)
            Network.cancel();
        else
            Network.join(network);
    }

    function openDetails(network: var): void {
        root.collapseExcept(network);
        root.toggleDetails(network);
    }

    // Whatever another row has open collapses: its details, or its prompt.
    function collapseExcept(network: var): void {
        root.closeDetailsExcept(network);
        if (Network.joining && Network.joining !== network)
            Network.abandon();
    }

    service: Network
    title: "network"
    items: Network.networks
    offText: "wi-fi is off"
    emptyText: "looking for networks"

    // Opens clean, and leaves nothing behind but a password already sent.
    Component.onCompleted: Network.abandon()
    Component.onDestruction: Network.abandon()

    delegate: NetworkRow {
        id: row

        required property var modelData

        width: ListView.view.width
        network: row.modelData
        // A forgotten network has no details left to show.
        detailsOpen: root.detailed === row.modelData && row.hasDetails
        onClicked: root.activate(row.modelData, row.expanded)
        onDetailsToggled: root.openDetails(row.modelData)
    }
}
