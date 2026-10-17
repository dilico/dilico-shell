pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services
import qs.utils

// One bluetooth device: what kind it is, its name over its battery and
// whether it is paired, and under it a paired device's details.
ListRow {
    id: root

    // Null once BlueZ drops the device, until the list catches up.
    required property var device

    readonly property string kind: Bluez.kind(root.device)
    readonly property bool paired: root.device?.paired ?? false
    readonly property bool trusted: root.device?.trusted ?? false
    // "84%", or "" for a device that does not report it.
    readonly property string battery: root.device?.batteryAvailable ? Format.percent(root.device?.battery ?? 0) : ""

    visible: root.device !== null
    title: Bluez.deviceName(root.device)
    subtitle: [root.kind, root.battery, root.paired && !root.current ? "paired" : ""].filter(part => part !== "").join(" · ")
    current: root.device?.connected ?? false
    busyText: Bluez.activity(root.device)
    hasDetails: root.paired

    leading: Label {
        text: Icons.device(root.kind)
        color: root.current ? Colors.text : Colors.textMid
        font.pixelSize: Typography.iconSize
    }

    body: DetailsPanel {
        facts: [
            ["battery", root.battery],
            ["address", root.device?.address ?? ""]
        ]
        switchLabel: "connect automatically"
        switchChecked: root.trusted
        canDisconnect: root.current
        forgetName: root.title
        onSwitchToggled: on => Bluez.setTrusted(root.device, on)
        onDisconnectClicked: Bluez.disconnect(root.device)
        onForgetClicked: Bluez.forget(root.device)
    }
}
