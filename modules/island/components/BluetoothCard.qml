pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// The bluetooth list. It decides what a click on a device does: one row has
// its details open at a time.
ListCard {
    id: root

    // A click on a row: the connected device opens its details, one under
    // way stops, and anything else is connected, paired first if it has to be.
    function activate(device: var): void {
        root.closeDetailsExcept(device);
        if (device?.connected)
            root.toggleDetails(device);
        else if (Bluez.activity(device) !== "")
            Bluez.stop(device);
        else
            Bluez.connect(device);
    }

    service: Bluez
    switchChecked: Bluez.enabled
    title: "bluetooth"
    items: Bluez.devices
    offText: Bluez.available ? "bluetooth is off" : "no bluetooth adapter"
    emptyText: "looking for devices"

    onSwitchToggled: on => Bluez.setEnabled(on)

    delegate: BluetoothRow {
        id: row

        required property var modelData

        width: ListView.view.width
        device: row.modelData
        // A forgotten device has no details left to show.
        detailsOpen: root.detailed === row.modelData && row.hasDetails
        onClicked: root.activate(row.modelData)
        onDetailsToggled: root.toggleDetails(row.modelData)
    }
}
