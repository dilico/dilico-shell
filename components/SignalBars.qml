pragma ComponentBehavior: Bound

import QtQuick
import qs.config

// Four rising bars, the first `lit` of them filled: a signal's strength.
Row {
    id: root

    // 0..4
    property int lit: 0
    property color litColor: Colors.textMid
    property color unlitColor: Colors.outline

    readonly property int barWidth: 3
    readonly property int step: 3

    spacing: 1

    Accessible.role: Accessible.Graphic
    Accessible.name: `signal ${root.lit} of 4`

    Repeater {
        model: 4

        Rectangle {
            required property int index

            y: root.step * (3 - index)
            width: root.barWidth
            height: root.step * (index + 1)
            radius: 0.5
            color: index < root.lit ? root.litColor : root.unlitColor
        }
    }
}
