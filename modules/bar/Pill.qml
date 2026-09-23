pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.modules.bar.panels
import qs.services

Item {
    id: root

    property string label: ""
    // Which panel is showing; "" is the icon row.
    property string selected: ""
    // True while an OSD triggered by an external volume change is on screen.
    property bool osd: false

    // Animated by the state transition; everything else derives from these.
    property real horizontalPadding: 10
    property real verticalPadding: 5
    property real popOffset: 0
    property real progress: 0

    property real formWidth: Math.max(contentWidth, text.implicitWidth) + hoverHPad * 2
    property real formHeight: contentHeight + hoverVPad * 2

    readonly property int hoverHPad: 12
    readonly property int hoverVPad: 7
    readonly property int hoverPop: 5

    readonly property real pillWidth: text.implicitWidth + horizontalPadding * 2
    readonly property real pillHeight: text.implicitHeight + verticalPadding * 2
    readonly property real contentWidth: selected === ""
        ? iconRow.implicitWidth : volumePanel.width
    readonly property real contentHeight: selected === ""
        ? iconRow.implicitHeight : volumePanel.implicitHeight

    // The window is sized from this and must never change size while open.
    readonly property real maxHeight: hoverPop + 400

    readonly property bool open: hoverHandler.hovered || volumePanel.interacting || osd

    // Staged so the clock and the panel hand over rather than overlap.
    readonly property real contentOpacity: Math.max(0, progress * 2 - 1)
    readonly property real labelOpacity: Math.max(0, 1 - progress * 2)

    function glyphFor(key: string): string {
        switch (key) {
        case "volume":
            return volumePanel.statusGlyph;
        case "network":
            return Glyphs.network;
        case "battery":
            return Glyphs.battery;
        case "bluetooth":
            return Glyphs.bluetooth;
        }
        return "";
    }

    // Covers the resting pill and the expanded form, so the hover region can
    // never shrink out from under the pointer mid-animation.
    implicitWidth: Math.max(text.implicitWidth + hoverHPad * 2, bg.width)
    implicitHeight: Math.max(text.implicitHeight + hoverVPad * 2 + hoverPop,
        popOffset + bg.height)

    // Reset only once fully closed: the opening animation writes progress 0 on
    // its first frame, which would otherwise clear a just-set selection.
    onProgressChanged: if (progress === 0 && !open) selected = ""

    Behavior on formWidth {
        NumberAnimation {
            duration: Animations.durationMedium
            easing.type: Animations.easingType
        }
    }

    Behavior on formHeight {
        NumberAnimation {
            duration: Animations.durationMedium
            easing.type: Animations.easingType
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    Timer {
        id: osdTimer

        interval: 1000
        onTriggered: root.osd = false
    }

    Connections {
        target: Audio

        function onChangedExternally(): void {
            root.selected = "volume";
            root.osd = true;
            osdTimer.restart();
        }
    }

    Rectangle {
        id: bg

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.popOffset
        anchors.alignWhenCentered: false
        width: root.pillWidth + (root.formWidth - root.pillWidth) * root.progress
        height: root.pillHeight + (root.formHeight - root.pillHeight) * root.progress
        clip: true

        radius: 10
        color: Colors.background
        border.width: 1
        border.color: Colors.border
        border.pixelAligned: false

        Text {
            id: text

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.verticalPadding
            // Whole-pixel centring plus fractional padding makes the text jitter.
            anchors.alignWhenCentered: false
            opacity: root.labelOpacity
            text: root.label
            color: Colors.text
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontSize
        }

        Row {
            id: iconRow

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.verticalPadding
            anchors.alignWhenCentered: false
            spacing: 4
            opacity: root.selected === "" ? root.contentOpacity : 0
            visible: opacity > 0

            Repeater {
                model: ["volume", "network", "battery", "bluetooth"]

                Icon {
                    required property var modelData

                    glyph: root.glyphFor(modelData)
                    active: root.selected === modelData
                    onClicked: root.selected = root.selected === modelData ? "" : modelData
                }
            }
        }

        VolumePanel {
            id: volumePanel

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.verticalPadding
            anchors.alignWhenCentered: false
            width: 260
            opacity: root.selected === "volume" ? root.contentOpacity : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Animations.durationShort
                    easing.type: Animations.easingType
                }
            }
        }
    }

    states: State {
        name: "open"
        when: root.open

        PropertyChanges {
            root.horizontalPadding: root.hoverHPad
            root.verticalPadding: root.hoverVPad
            root.popOffset: root.hoverPop
            root.progress: 1
        }
    }

    transitions: Transition {
        NumberAnimation {
            properties: "horizontalPadding,verticalPadding,popOffset,progress"
            duration: Animations.durationMedium
            easing.type: Animations.easingType
        }
    }
}
