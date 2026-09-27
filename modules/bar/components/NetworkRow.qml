import QtQuick
import qs.config
import qs.services

Item {
    id: root

    required property var network

    signal selected()
    signal forgotten()

    function strengthGlyph(strength: real): string {
        if (strength >= 0.75)
            return Glyphs.networkStrength4;
        if (strength >= 0.5)
            return Glyphs.networkStrength3;
        if (strength >= 0.25)
            return Glyphs.networkStrength2;
        return Glyphs.networkStrength1;
    }

    implicitHeight: 36

    // Reveals the forget button. It covers the whole row, so moving onto the
    // button cannot hide it out from under the pointer.
    HoverHandler {
        id: rowHover
    }

    // Everything up to the forget button selects the network. The button sits
    // outside it so one tap never does both.
    Item {
        id: selectArea

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: forget.visible ? forget.left : padlock.left
        anchors.rightMargin: 8

        Text {
            id: strength

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.strengthGlyph(root.network.signalStrength)
            color: root.network.connected ? Colors.accent : Colors.textDim
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontSizeSmall
        }

        Text {
            id: ssid

            anchors.left: strength.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            // Shrinks rather than pushing the percentage off the row.
            width: Math.min(implicitWidth, parent.width - strength.width - percent.implicitWidth - 14)
            elide: Text.ElideRight
            text: root.network.name
            color: selectHover.hovered || root.network.connected ? Colors.accent : Colors.textDim
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontSizeSmall
        }

        Text {
            id: percent

            anchors.left: ssid.right
            anchors.leftMargin: 6
            anchors.baseline: ssid.baseline
            text: `${Math.round(root.network.signalStrength * 100)}%`
            color: Colors.textDim
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontSizeCaption
        }

        HoverHandler {
            id: selectHover

            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: root.selected()
        }
    }

    Text {
        id: padlock

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: Network.secured(root.network) ? Glyphs.lock : ""
        color: Colors.textDim
        font.family: Typography.fontFamily
        font.pixelSize: Typography.fontSizeSmall
    }

    // Only a saved network has anything to clear.
    Item {
        id: forget

        anchors.right: padlock.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: forgetLabel.implicitWidth + 16
        implicitHeight: forgetLabel.implicitHeight + 8
        visible: root.network.known
        opacity: rowHover.hovered ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Animations.durationShort
                easing.type: Animations.easingType
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: forgetHover.hovered ? Qt.alpha(Colors.accent, 0.12) : "transparent"
            border.width: 1
            border.color: Colors.border
        }

        Text {
            id: forgetLabel

            anchors.centerIn: parent
            text: "Forget"
            color: forgetHover.hovered ? Colors.accent : Colors.textDim
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontSizeSmall
        }

        HoverHandler {
            id: forgetHover

            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: root.forgotten()
        }
    }
}
