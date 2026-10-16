pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    id: root

    // The action waiting for its confirming second click, or "". Everything but
    // lock ends the session, so one stray click must never be enough.
    property string armed: ""

    // Each action says whether it needs that second click and what it runs.
    readonly property var actions: [
        {
            key: "lock",
            glyph: Glyphs.lock,
            label: "lock",
            confirm: false,
            run: () => Session.lock()
        },
        {
            key: "logout",
            glyph: Glyphs.logout,
            label: "log out",
            confirm: true,
            run: () => Session.logout()
        },
        {
            key: "reboot",
            glyph: Glyphs.restart,
            label: "reboot",
            confirm: true,
            run: () => Session.reboot()
        },
        {
            key: "poweroff",
            glyph: Glyphs.power,
            label: "power off",
            confirm: true,
            run: () => Session.poweroff()
        }
    ]

    readonly property string armedLabel: root.actions.find(a => a.key === root.armed)?.label ?? ""

    function activate(action: var): void {
        if (action.confirm && root.armed !== action.key) {
            root.armed = action.key;
            disarm.restart();
            return;
        }
        root.armed = "";
        action.run();
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Timer {
        id: disarm

        interval: 3000
        onTriggered: root.armed = ""
    }

    // Hangs off to the left, into the header's empty middle.
    Subtext {
        anchors.right: row.left
        anchors.rightMargin: 12
        anchors.verticalCenter: row.verticalCenter
        visible: root.armed !== ""
        text: `click again to ${root.armedLabel}`
        color: Colors.textMid
    }

    Row {
        id: row

        anchors.right: parent.right
        spacing: 6

        Repeater {
            model: root.actions

            IconButton {
                id: button

                required property var modelData

                glyph: button.modelData.glyph
                label: button.modelData.label
                highlighted: root.armed === button.modelData.key
                onClicked: root.activate(button.modelData)
            }
        }
    }
}
