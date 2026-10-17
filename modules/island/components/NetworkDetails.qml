pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services
import qs.utils

// What is known about a saved network beyond its row, and what can be done
// with it: join it automatically or not, disconnect, forget. Its row insets
// it.
Column {
    id: root

    required property var network
    required property bool connected

    // The saved profile, read when this opens and again whenever
    // NetworkManager says it changed: it is not something to bind to.
    property var saved: Network.savedDetails(null)
    property real now: 0

    // Each [label, value]; a fact with nothing to say is left out.
    readonly property var facts: [
        ["internet", root.connected ? Network.internet : ""],
        ["access points", root.saved.accessPoints > 0 ? String(root.saved.accessPoints) : ""],
        ["last used", !root.connected && root.saved.lastUsed > 0 ? Format.ago(root.saved.lastUsed, root.now) : ""],
        ["interface", root.connected ? Network.interfaceName : ""],
        ["mac address", root.connected ? Network.hardwareAddress : ""]
    ].filter(fact => fact[1] !== "")

    function refresh(): void {
        root.saved = Network.savedDetails(root.network);
        root.now = Date.now() / 1000;
    }

    spacing: 4

    Component.onCompleted: root.refresh()

    Connections {
        target: Network.savedSettings(root.network)
        ignoreUnknownSignals: true

        function onSettingsChanged(): void {
            root.refresh();
        }
    }

    Repeater {
        model: root.facts

        Row {
            id: fact

            required property var modelData

            spacing: 8

            Caption {
                width: 92
                text: fact.modelData[0]
            }

            Caption {
                text: fact.modelData[1]
                color: Colors.textMid
            }
        }
    }

    Item {
        width: parent.width
        height: 28

        Switch {
            id: autoJoin

            objectName: "autoJoin"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            checked: root.saved.autoJoin

            Accessible.name: "join automatically"

            // Shown at once; the profile's settingsChanged confirms it.
            onClicked: {
                Network.setAutoJoin(root.network, !root.saved.autoJoin);
                root.saved = Object.assign({}, root.saved, {
                    autoJoin: !root.saved.autoJoin
                });
            }
        }

        Caption {
            anchors.left: autoJoin.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "join automatically"
            color: Colors.textMid
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            TextButton {
                objectName: "disconnect"
                visible: root.connected
                text: "disconnect"
                onClicked: Network.disconnect(root.network)
            }

            TextButton {
                objectName: "forget"
                text: "forget"
                accessibleName: `forget ${root.network?.name ?? ""}`
                onClicked: Network.forget(root.network)
            }
        }
    }
}
