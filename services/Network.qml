pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    // Set true by a consumer showing the list, so the radio only scans while
    // something is looking at it.
    property bool scanning: false

    // NetworkManager exposes no scan-in-progress signal, so a refresh is shown
    // for a fixed time rather than until the radio actually finishes.
    property bool refreshing: false

    readonly property bool enabled: Networking.wifiEnabled

    // Empty until the NetworkManager backend finishes connecting, about a
    // second after startup, so everything downstream has to be a binding.
    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    // Strongest first. The connected one is not pinned to the top: it is
    // already marked in accent, and a fixed order is easier to scan.
    readonly property var networks: (root.device?.networks?.values ?? []).filter(n => n.name !== "").sort((a, b) => {
        if (a.signalStrength !== b.signalStrength)
            return b.signalStrength - a.signalStrength;
        return a.name.localeCompare(b.name, undefined, {
            numeric: true
        });
    })

    readonly property var active: root.networks.find(n => n.connected) ?? null

    function setEnabled(on: bool): void {
        Networking.wifiEnabled = on;
    }

    function applyScanner(): void {
        if (root.device)
            root.device.scannerEnabled = root.scanning;
    }

    // Cycling the scanner is what asks NetworkManager for a fresh sweep.
    function refresh(): void {
        if (!root.device)
            return;
        root.refreshing = true;
        root.device.scannerEnabled = false;
        root.device.scannerEnabled = true;
        refreshTimer.restart();
    }

    function connect(network: var): void {
        network.connect();
    }

    function connectWithPassword(network: var, password: string): void {
        network.connectWithPsk(password);
    }

    function forget(network: var): void {
        network.forget();
    }

    function secured(network: var): bool {
        return network?.security !== WifiSecurityType.Open;
    }

    // NetworkManager reports a missing secret and a rejected one the same way,
    // so the caller has to know whether it supplied a password.
    function needsPassword(reason: int): bool {
        return reason === ConnectionFailReason.NoSecrets;
    }

    function failureMessage(reason: int): string {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "Wrong password";
        case ConnectionFailReason.WifiAuthTimeout:
            return "Authentication timed out";
        case ConnectionFailReason.WifiNetworkLost:
            return "Network out of range";
        }
        return "Could not connect";
    }

    onScanningChanged: root.applyScanner()
    onDeviceChanged: root.applyScanner()

    Timer {
        id: refreshTimer

        interval: 1500
        onTriggered: root.refreshing = false
    }
}
