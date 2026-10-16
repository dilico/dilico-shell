pragma ComponentBehavior: Bound

import QtQuick
import qs.config

Item {
    id: root

    // [{ key: string, label: string }]
    property var options: []
    property string current: ""

    signal picked(string key)

    implicitWidth: 300
    implicitHeight: 36

    Accessible.role: Accessible.PageTabList

    Surface {
        anchors.fill: parent
    }

    Row {
        id: row

        anchors.fill: parent
        anchors.margins: 3
        spacing: 3

        Repeater {
            model: root.options

            Pressable {
                id: option

                required property var modelData
                readonly property bool selected: option.modelData.key === root.current

                width: (row.width - row.spacing * (root.options.length - 1)) / root.options.length
                height: row.height

                Accessible.role: Accessible.PageTab
                Accessible.name: option.modelData.label
                Accessible.selected: option.selected

                onClicked: root.picked(option.modelData.key)

                Surface {
                    anchors.fill: parent
                    radius: Rounding.small
                    active: option.selected
                    hovered: option.hovered
                    restColor: "transparent"
                    activeColor: Colors.surfaceRaised
                }

                Subtext {
                    anchors.centerIn: parent
                    text: option.modelData.label
                    color: option.selected ? Colors.text : Colors.textDim
                }
            }
        }
    }
}
