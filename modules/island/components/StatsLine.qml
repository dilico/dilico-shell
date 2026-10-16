import QtQuick
import qs.components
import qs.config
import qs.services
// qmllint disable unused-imports
// False positive: qmllint does not count a use inside a template literal in a
// ternary's branch, which is where this file's uses of Format sit.
import qs.utils
// qmllint enable unused-imports

Item {
    id: root

    readonly property string batteryText: {
        if (!Battery.available)
            return "";
        const pct = `bat ${Format.percent(Battery.level)}`;
        if (Battery.charging)
            return Battery.timeToFull > 0 ? `${pct} · full in ${Format.duration(Battery.timeToFull)}` : `${pct} · charging`;
        return Battery.timeToEmpty > 0 ? `${pct} · ${Format.duration(Battery.timeToEmpty)}` : pct;
    }

    implicitWidth: 600
    implicitHeight: 30

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: Colors.divider
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        spacing: 18

        Caption {
            text: SystemStats.cpu < 0 ? "cpu --" : `cpu ${Format.percent(SystemStats.cpu)}`
        }

        Caption {
            visible: SystemStats.memTotal > 0
            text: `mem ${SystemStats.memUsed.toFixed(1)}/${Math.round(SystemStats.memTotal)}g`
        }

        Caption {
            visible: SystemStats.temperature >= 0
            text: `${Math.round(SystemStats.temperature)}°c`
        }

        Caption {
            visible: root.batteryText !== ""
            text: root.batteryText
        }
    }

    Caption {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        text: "arch · hyprland"
    }
}
