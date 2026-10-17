pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config

// What a list row's details hold: facts as label and value, a switch, and
// disconnect and forget. Its row insets it.
Column {
    id: root

    // Each [label, value]; a fact with nothing to say is left out.
    property var facts: []
    property string switchLabel: ""
    property bool switchChecked: false
    property bool canDisconnect: false
    // What forget forgets, for assistive tech.
    property string forgetName: ""

    signal switchToggled(bool on)
    signal disconnectClicked()
    signal forgetClicked()

    spacing: 4

    Repeater {
        model: root.facts.filter(fact => fact[1] !== "")

        Row {
            id: fact

            required property var modelData

            spacing: 8

            Caption {
                width: 92
                text: fact.modelData[0]
            }

            Caption {
                text: fact.modelData[1]
                color: Colors.textMid
            }
        }
    }

    Item {
        width: parent.width
        height: 28

        Switch {
            id: toggle

            objectName: "detailSwitch"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            checked: root.switchChecked

            Accessible.name: root.switchLabel

            onClicked: root.switchToggled(!root.switchChecked)
        }

        Caption {
            anchors.left: toggle.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.switchLabel
            color: Colors.textMid
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            TextButton {
                objectName: "disconnect"
                visible: root.canDisconnect
                text: "disconnect"
                onClicked: root.disconnectClicked()
            }

            TextButton {
                objectName: "forget"
                text: "forget"
                accessibleName: `forget ${root.forgetName}`
                onClicked: root.forgetClicked()
            }
        }
    }
}
