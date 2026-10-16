import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.modules.island.components
import qs.services
import qs.utils

Item {
    id: root

    required property date date

    readonly property int padding: 20
    // Tighter than the sides: the big clock's line height already adds space
    // above it.
    readonly property int topPadding: 16

    function bluetoothSubtitle(): string {
        if (!Bluez.available)
            return "no adapter";
        if (!Bluez.enabled)
            return "off";
        const n = Bluez.connected.length;
        if (n === 0)
            return "on";
        return n === 1 ? Bluez.deviceName(Bluez.connected[0]) : `${n} connected`;
    }

    implicitWidth: 780
    implicitHeight: layout.implicitHeight + root.topPadding + root.padding

    // The polled services poll while the dashboard exists, and stop with it.
    Watch {
        service: Brightness
    }

    Watch {
        service: Media
    }

    Watch {
        service: SystemStats
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        anchors.topMargin: root.topPadding
        anchors.bottomMargin: root.padding
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Label {
                Layout.alignment: Qt.AlignBottom
                text: Format.time(root.date)
                font.pixelSize: Typography.clockSize
                font.weight: Font.Light
                font.letterSpacing: -2
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 8
                spacing: 2

                Label {
                    text: Format.date(root.date, "dddd")
                    font.weight: Font.DemiBold
                }

                Subtext {
                    text: Format.date(root.date, "d MMMM")
                }
            }

            Item {
                Layout.fillWidth: true
            }

            SessionButtons {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 6
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                id: controls

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 12

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    Tile {
                        Layout.fillWidth: true
                        glyph: Icons.wifi(Network.connected, Network.strength)
                        title: "network"
                        subtitle: !Network.enabled ? "off" : (Network.activeName || "disconnected")
                        active: Network.enabled
                        onClicked: Network.setEnabled(!Network.enabled)
                    }

                    Tile {
                        Layout.fillWidth: true
                        glyph: Icons.bluetooth(Bluez.enabled, Bluez.connected.length)
                        title: "bluetooth"
                        subtitle: root.bluetoothSubtitle()
                        active: Bluez.enabled
                        onClicked: Bluez.setEnabled(!Bluez.enabled)
                    }

                    Tile {
                        Layout.fillWidth: true
                        glyph: Idle.inhibited ? Glyphs.coffee : Glyphs.coffeeOff
                        title: "keep awake"
                        subtitle: Idle.inhibited ? "on · no idle lock" : "off"
                        active: Idle.inhibited
                        onClicked: Idle.toggle()
                    }

                    Tile {
                        Layout.fillWidth: true
                        glyph: Radios.airplane ? Glyphs.airplane : Glyphs.airplaneOff
                        title: "airplane"
                        subtitle: Radios.airplane ? "radios off" : "off"
                        active: Radios.airplane
                        onClicked: Radios.setAirplane(!Radios.airplane)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    SliderRow {
                        Layout.fillWidth: true
                        label: "volume"
                        glyph: Icons.volume(Audio.muted, Audio.volume)
                        value: Audio.volume
                        muted: Audio.muted
                        onMoved: v => Audio.setVolume(v)
                        onToggled: Audio.toggleMuted()
                    }

                    SliderRow {
                        Layout.fillWidth: true
                        label: "microphone"
                        glyph: Audio.micMuted ? Glyphs.microphoneOff : Glyphs.microphone
                        value: Audio.micVolume
                        muted: Audio.micMuted
                        onMoved: v => Audio.setMicVolume(v)
                        onToggled: Audio.toggleMicMuted()
                    }

                    SliderRow {
                        Layout.fillWidth: true
                        visible: Brightness.available
                        label: "brightness"
                        glyph: Glyphs.brightness
                        toggleable: false
                        value: Brightness.level
                        onMoved: v => Brightness.setLevel(v)
                    }
                }

                Segmented {
                    Layout.fillWidth: true
                    options: PowerMode.profiles.map(key => ({
                                key,
                                label: key === "saver" ? "power saver" : key
                            }))
                    current: PowerMode.profile
                    onPicked: key => PowerMode.setProfile(key)
                }
            }

            // As tall as the controls column and no taller; notifications take
            // whatever the media card leaves.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: controls.implicitHeight
                Layout.alignment: Qt.AlignTop
                spacing: 8

                MediaCard {
                    Layout.fillWidth: true
                }

                NotificationCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }

        StatsLine {
            Layout.fillWidth: true
        }
    }
}
