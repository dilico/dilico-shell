pragma Singleton

import QtQuick
import Quickshell

// Stands in for services/Bluez in tests: the same interface as far as the
// device list uses it, recording what was asked instead of asking BlueZ. A
// test device is a QtObject with name, kind, connected, paired, trusted,
// activity, batteryAvailable, battery and address.
Singleton {
    id: root

    property int watchers: 0
    property bool available: true
    property bool enabled: true
    property var devices: []
    // Each request as [name, argument]; reset by tests.
    property var calls: []

    function deviceName(device: var): string {
        return device?.name || "device";
    }

    function kind(device: var): string {
        return device?.kind ?? "device";
    }

    function activity(device: var): string {
        return device?.activity ?? "";
    }

    function setEnabled(on: bool): void {
        root.calls.push(["setEnabled", on]);
    }

    function connect(device: var): void {
        root.calls.push(["connect", device.name]);
    }

    function stop(device: var): void {
        root.calls.push(["stop", device.name]);
    }

    function disconnect(device: var): void {
        root.calls.push(["disconnect", device.name]);
    }

    function forget(device: var): void {
        root.calls.push(["forget", device.name]);
    }

    function setTrusted(device: var, on: bool): void {
        root.calls.push(["setTrusted", on]);
    }
}
