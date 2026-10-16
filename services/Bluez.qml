pragma Singleton

import Quickshell
import Quickshell.Bluetooth

// Named for the daemon rather than "Bluetooth", which would shadow the
// Quickshell.Bluetooth singleton this file reads from.
Singleton {
    id: root

    // qmllint disable unresolved-type
    // False positive: BluetoothAdapter is declared in the same qmltypes file as
    // Bluetooth, but qmllint does not resolve it as the property's type.
    readonly property var adapter: Bluetooth.defaultAdapter
    // qmllint enable unresolved-type

    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.adapter?.enabled ?? false
    readonly property var connected: (root.adapter?.devices?.values ?? []).filter(d => d.connected)

    function setEnabled(on: bool): void {
        if (root.adapter)
            root.adapter.enabled = on;
    }

    function deviceName(device: var): string {
        return device?.name || device?.deviceName || "device";
    }
}
