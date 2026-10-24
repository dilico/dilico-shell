pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config

// A screen's workspaces as the pill shows them for a moment after a switch:
// their numbers, the current one inverted the way an active tile is. Shown,
// never touched.
Row {
    id: root

    // [{ number: int, current: bool }], in order.
    property var workspaces: []

    spacing: 2

    Repeater {
        objectName: "chips"
        model: root.workspaces

        // A fixed size, so "10" takes no more room than "1" and the pill
        // holds its width across a switch that only moves the highlight.
        Surface {
            id: chip

            required property var modelData

            width: 22
            height: 22
            radius: Rounding.small
            restColor: "transparent"
            active: chip.modelData.current

            Subtext {
                anchors.centerIn: parent
                text: chip.modelData.number
                color: chip.modelData.current ? Colors.activeText : Colors.textDim
                font.weight: chip.modelData.current ? Font.DemiBold : Font.Normal
            }
        }
    }
}
