pragma Singleton

import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    // UPower fills this in a moment after startup, and only once a binding has
    // asked for it, so everything downstream must be a binding too.
    readonly property var device: UPower.displayDevice

    readonly property bool available: root.device?.isLaptopBattery ?? false
    readonly property real level: root.device?.percentage ?? 0
    readonly property bool charging: root.device?.state === UPowerDeviceState.Charging

    // Seconds. UPower reports 0 while it has no estimate yet.
    readonly property real timeToFull: root.device?.timeToFull ?? 0
    readonly property real timeToEmpty: root.device?.timeToEmpty ?? 0
}
