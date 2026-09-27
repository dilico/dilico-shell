pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    id: root

    property real padding: 10

    readonly property bool interacting: slider.pressed
    readonly property real contentInset: muteButton.padding
    readonly property string statusGlyph: Audio.muted || Audio.volume === 0
        ? Glyphs.volumeOff
        : Audio.volume < 0.5 ? Glyphs.volumeMedium : Glyphs.volume

    function outputGlyph(node: var): string {
        const name = Audio.shortName(node).toLowerCase();
        if (name.includes("hdmi") || name.includes("displayport"))
            return Glyphs.monitor;
        if (name.includes("head") || name.includes("earphone"))
            return Glyphs.headphones;
        return Glyphs.speaker;
    }

    implicitWidth: 380
    implicitHeight: column.implicitHeight + root.padding * 2

    // Availability only needs probing while someone is looking at the list.
    Binding {
        target: Audio
        property: "watchRoutes"
        value: root.visible
    }

    Column {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.padding
        // Extra on the right to match the leading glyph's own padding.
        anchors.rightMargin: root.padding + root.contentInset
        anchors.topMargin: root.padding
        spacing: 12

        SectionLabel {
            text: Audio.muted ? "Volume · muted" : "Volume"
        }

        Row {
            width: parent.width
            spacing: 12

            Icon {
                id: muteButton

                glyph: root.statusGlyph
                active: Audio.muted
                activeColor: Colors.textDim
                onClicked: Audio.toggleMuted()
            }

            Slider {
                id: slider

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - muteButton.width - parent.spacing
                opacity: Audio.muted ? 0.4 : 1
                value: Audio.volume
                onMoved: v => Audio.setVolume(v)
            }
        }

        SectionLabel {
            text: "Audio output"
        }

        Column {
            width: parent.width
            spacing: 6

            Repeater {
                model: Audio.sinks

                delegate: Item {
                    id: option

                    required property var modelData
                    readonly property bool current: modelData === Audio.sink

                    width: parent.width
                    implicitHeight: 36

                    Text {
                        id: kind

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.outputGlyph(option.modelData)
                        color: option.current ? Colors.accent : Colors.textDim
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontSizeSmall
                    }

                    Text {
                        anchors.left: kind.right
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: Audio.shortName(option.modelData)
                        color: optionHover.hovered || option.current
                            ? Colors.accent : Colors.textDim
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontSizeSmall
                    }

                    HoverHandler {
                        id: optionHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: Audio.setSink(option.modelData)
                    }
                }
            }
        }
    }
}
