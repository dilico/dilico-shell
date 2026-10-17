import QtQuick
import qs.components
import qs.config
import qs.services
// qmllint disable unused-imports
// False positive: qmllint does not count a use inside a template literal in a
// ternary's branch, which is where this file's uses of Format sit.
import qs.utils
// qmllint enable unused-imports

// The line along the dashboard's foot. The cpu and memory figures open the
// heaviest processes, sorted by that figure.
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

    // "cpu" or "memory".
    signal processesClicked(string by)

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

        Figure {
            objectName: "cpu"
            text: SystemStats.cpu < 0 ? "cpu --" : `cpu ${Format.percent(SystemStats.cpu)}`
            Accessible.name: "processes by cpu"
            onClicked: root.processesClicked("cpu")
        }

        Figure {
            objectName: "memory"
            visible: SystemStats.memTotal > 0
            text: `mem ${SystemStats.memUsed.toFixed(1)}/${Math.round(SystemStats.memTotal)}g`
            Accessible.name: "processes by memory"
            onClicked: root.processesClicked("memory")
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

    // A figure to click, built as TextButton is at the caption's size: it
    // brightens under the pointer, and the hit area reaches a little past it.
    component Figure: Item {
        id: figure

        property alias text: label.text

        signal clicked()

        implicitWidth: label.implicitWidth
        implicitHeight: label.implicitHeight

        Pressable {
            id: hit

            anchors.fill: parent
            anchors.margins: -6

            Accessible.name: figure.Accessible.name

            onClicked: figure.clicked()
        }

        Caption {
            id: label

            color: hit.hovered ? Colors.text : Colors.textDim
        }
    }
}
