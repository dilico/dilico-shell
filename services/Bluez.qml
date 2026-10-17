pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Named for the daemon rather than "Bluetooth", which would shadow the
// Quickshell.Bluetooth singleton this file reads from.
Singleton {
    id: root

    // How many things are showing the device list, each through a Watch. The
    // adapter only searches for new devices while something is looking.
    property int watchers: 0

    // A device being paired so it can be connected once the pairing lands, or
    // null.
    property var pairingWith: null

    // qmllint disable unresolved-type
    // False positive: BluetoothAdapter is declared in the same qmltypes file as
    // Bluetooth, but qmllint does not resolve it as the property's type.
    readonly property var adapter: Bluetooth.defaultAdapter
    // qmllint enable unresolved-type

    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.adapter?.enabled ?? false
    readonly property var connected: (root.adapter?.devices?.values ?? []).filter(d => d.connected)

    // Connected first, then paired, then by name. A device found nearby that
    // gives only its address has nothing to show, so it is left out. Worked
    // out only while something shows it.
    readonly property var devices: root.watchers === 0 ? [] : (root.adapter?.devices?.values ?? []).filter(d => d.paired || !root.nameless(d)).sort((a, b) => {
        if (a.connected !== b.connected)
            return a.connected ? -1 : 1;
        if (a.paired !== b.paired)
            return a.paired ? -1 : 1;
        return root.deviceName(a).localeCompare(root.deviceName(b), undefined, {
            numeric: true
        });
    })

    function setEnabled(on: bool): void {
        if (root.adapter)
            root.adapter.enabled = on;
    }

    function deviceName(device: var): string {
        return device?.name || device?.deviceName || "device";
    }

    // BlueZ names a device by its address until the device says otherwise.
    function nameless(device: var): bool {
        const name = device?.name ?? "";
        return name === "" || /^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(name);
    }

    // What sort of thing it is, from the icon name BlueZ gives it.
    function kind(device: var): string {
        switch (device?.icon ?? "") {
        case "audio-headphones":
            return "headphones";
        case "audio-headset":
            return "headset";
        case "audio-card":
        case "audio-speakers":
            return "speaker";
        case "input-keyboard":
            return "keyboard";
        case "input-mouse":
            return "mouse";
        case "input-gaming":
            return "controller";
        case "input-tablet":
            return "tablet";
        case "phone":
            return "phone";
        case "computer":
            return "computer";
        case "video-display":
            return "display";
        }
        return "device";
    }

    // What it is busy doing, in words, or "".
    function activity(device: var): string {
        if (device?.pairing)
            return "pairing";
        switch (device?.state) {
        case BluetoothDeviceState.Connecting:
            return "connecting";
        case BluetoothDeviceState.Disconnecting:
            return "disconnecting";
        }
        return "";
    }

    // Connects a paired device; pairs an unknown one first, and connects it
    // once the pairing lands.
    function connect(device: var): void {
        if (!device)
            return;
        if (device.paired) {
            device.connect();
            return;
        }
        root.pairingWith = device;
        device.pair();
    }

    // Stops a pairing or a connection under way.
    function stop(device: var): void {
        if (device?.pairing)
            device.cancelPair();
        else
            device?.disconnect();
    }

    function disconnect(device: var): void {
        device?.disconnect();
    }

    function forget(device: var): void {
        if (device === root.pairingWith)
            root.pairingWith = null;
        device?.forget();
    }

    // A trusted device may connect by itself when it comes in range.
    function setTrusted(device: var, on: bool): void {
        if (device)
            device.trusted = on;
    }

    // Once a pairing lands the device is trusted, so it comes back by itself,
    // and connected; a pairing that ends unpaired failed or was cancelled.
    function settlePairing(): void {
        const device = root.pairingWith;
        if (!device || device.pairing)
            return;
        if (device.paired) {
            device.trusted = true;
            device.connect();
        }
        root.pairingWith = null;
    }

    function applyDiscovery(): void {
        if (root.adapter)
            root.adapter.discovering = root.watchers > 0 && root.enabled;
    }

    onWatchersChanged: root.applyDiscovery()
    onAdapterChanged: root.applyDiscovery()
    onEnabledChanged: root.applyDiscovery()

    Connections {
        target: root.pairingWith

        function onPairingChanged(): void {
            root.settlePairing();
        }

        function onPairedChanged(): void {
            root.settlePairing();
        }
    }
}
