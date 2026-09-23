pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    id: root

    readonly property bool interacting: slider.pressed
    readonly property real contentInset: muteButton.padding
    readonly property string statusGlyph: Audio.muted || Audio.volume === 0
        ? Glyphs.volumeOff
        : Audio.volume < 0.5 ? Glyphs.volumeMedium : Glyphs.volume

    property bool listOpen: false

    implicitWidth: 260
    implicitHeight: column.implicitHeight

    onVisibleChanged: if (!visible) root.listOpen = false

    // Availability only needs probing while someone is looking at the list.
    Binding {
        target: Audio
        property: "watchRoutes"
        value: root.visible
    }

    Column {
        id: column

        // Inset on the right to match the glyph's own padding on the left.
        width: parent.width - root.contentInset
        spacing: 6

        Row {
            width: parent.width
            spacing: 6

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

        Item {
            width: parent.width
            implicitHeight: 24

            Text {
                anchors.left: parent.left
                anchors.right: chevron.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: Audio.shortName(Audio.sink)
                color: Colors.text
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontSizeSmall
            }

            Text {
                id: chevron

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.listOpen ? Glyphs.chevronUp : Glyphs.chevronDown
                color: Colors.textDim
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontSizeSmall
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.listOpen = !root.listOpen
            }
        }

        Column {
            width: parent.width
            spacing: 2
            visible: root.listOpen

            Repeater {
                model: Audio.sinks

                delegate: Item {
                    id: option

                    required property var modelData
                    readonly property bool current: modelData === Audio.sink

                    width: parent.width
                    implicitHeight: 22

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.right: tick.left
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: Audio.shortName(option.modelData)
                        color: optionHover.hovered || option.current
                            ? Colors.accent : Colors.textDim
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontSizeSmall
                    }

                    Text {
                        id: tick

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: option.current ? Glyphs.check : ""
                        color: Colors.accent
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontSizeSmall
                    }

                    HoverHandler {
                        id: optionHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            Audio.setSink(option.modelData);
                            root.listOpen = false;
                        }
                    }
                }
            }
        }
    }
}
