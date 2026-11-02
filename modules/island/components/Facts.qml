pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config

// Facts about a list row, as label and value, under the row.
Column {
    id: root

    // Each [label, value]; a fact with nothing to say is left out.
    property var facts: []

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
}
