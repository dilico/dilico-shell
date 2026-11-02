import QtQuick
import qs.services
import qs.utils

// A saved network's details: what its profile says, auto-join, disconnect
// and forget.
DetailsPanel {
    id: root

    required property var network
    required property bool connected

    // The saved profile, read when this opens and again whenever
    // NetworkManager says it changed: it is not something to bind to.
    property var saved: Network.savedDetails(null)
    property real now: 0

    function refresh(): void {
        root.saved = Network.savedDetails(root.network);
        root.now = Date.now() / 1000;
    }

    facts: [
        ["internet", root.connected ? Network.internet : ""],
        ["ip address", root.connected ? Network.address : ""],
        ["access points", root.saved.accessPoints > 0 ? String(root.saved.accessPoints) : ""],
        ["last used", !root.connected && root.saved.lastUsed > 0 ? Format.ago(root.saved.lastUsed, root.now) : ""],
        ["interface", root.connected ? Network.interfaceName : ""],
        ["mac address", root.connected ? Network.hardwareAddress : ""]
    ]
    switchLabel: "join automatically"
    switchChecked: root.saved.autoJoin
    canDisconnect: root.connected
    forgetName: root.network?.name ?? ""

    Component.onCompleted: root.refresh()

    // Shown at once; the profile's settingsChanged confirms it.
    onSwitchToggled: on => {
        Network.setAutoJoin(root.network, on);
        root.saved = Object.assign({}, root.saved, {
            autoJoin: on
        });
    }
    onDisconnectClicked: Network.disconnect(root.network)
    onForgetClicked: Network.forget(root.network)

    Connections {
        target: Network.savedSettings(root.network)
        ignoreUnknownSignals: true

        function onSettingsChanged(): void {
            root.refresh();
        }
    }
}
