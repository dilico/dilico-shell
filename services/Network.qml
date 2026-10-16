pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property bool enabled: Networking.wifiEnabled

    // Empty until the NetworkManager backend finishes connecting, about a
    // second after startup, so everything downstream has to be a binding.
    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property var active: (root.device?.networks?.values ?? []).find(n => n.connected) ?? null
    readonly property string activeName: root.active?.name ?? ""
    readonly property bool connected: root.enabled && root.active !== null

    // 0..1
    readonly property real strength: root.active?.signalStrength ?? 0

    function setEnabled(on: bool): void {
        Networking.wifiEnabled = on;
    }
}
