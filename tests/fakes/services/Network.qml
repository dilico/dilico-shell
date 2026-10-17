pragma Singleton

import QtQuick
import Quickshell

// Stands in for services/Network in tests: the same interface as far as the
// network list uses it, recording what was asked instead of asking
// NetworkManager. A test network is a QtObject with name, signalStrength,
// connected, known, secured and connecting.
Singleton {
    id: root

    property int watchers: 0
    property var joining: null
    property bool needsPassword: false
    property bool busy: false
    property string failure: ""
    property bool enabled: true
    property var networks: []
    property string internet: "online"
    property string interfaceName: "wlan0"
    property string hardwareAddress: "00:11:22:33:44:55"
    // Each request as [name, argument]; reset by tests.
    property var calls: []

    function secured(network: var): bool {
        return network?.secured ?? false;
    }

    function securityName(network: var): string {
        return network?.secured ? "wpa2" : "open";
    }

    function connecting(network: var): bool {
        return network?.connecting ?? false;
    }

    function savedSettings(network: var): var {
        return null;
    }

    function savedDetails(network: var): var {
        return {
            autoJoin: true,
            lastUsed: 0,
            accessPoints: network?.known ? 2 : 0
        };
    }

    function setAutoJoin(network: var, on: bool): void {
        root.calls.push(["setAutoJoin", on]);
    }

    function disconnect(network: var): void {
        root.calls.push(["disconnect", network.name]);
    }

    function setEnabled(on: bool): void {
        root.calls.push(["setEnabled", on]);
        root.enabled = on;
    }

    function join(network: var): void {
        root.calls.push(["join", network.name]);
        root.joining = network;
        root.needsPassword = network.secured && !network.known;
    }

    function submit(password: string): void {
        root.calls.push(["submit", password]);
    }

    function cancel(): void {
        root.calls.push(["cancel", ""]);
        root.joining = null;
        root.needsPassword = false;
        root.busy = false;
        root.failure = "";
    }

    function abandon(): void {
        if (!root.busy)
            root.cancel();
    }

    function forget(network: var): void {
        root.calls.push(["forget", network.name]);
    }
}
