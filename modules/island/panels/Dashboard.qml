pragma ComponentBehavior: Bound

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

    // What the right-hand column shows: media and notifications, one of the
    // lists, the calendar, the processes or the displays. Back to home
    // whenever the dashboard opens, since it is rebuilt each time.
    property Component pane: homePane
    // What the processes pane is sorted by: "cpu" or "memory".
    property string processSort: "cpu"

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

    // A pane opened by what opened it, the same way as a toggle: the clock
    // and date, or "displays", again closes it.
    function togglePane(pane: Component): void {
        root.pane = root.pane === pane ? homePane : pane;
    }

    // A figure in the stats line opens the processes sorted by it, and the
    // same figure again closes them.
    function showProcesses(by: string): void {
        if (root.pane === processesPane && root.processSort === by) {
            root.pane = homePane;
            return;
        }
        root.processSort = by;
        root.pane = processesPane;
    }

    implicitWidth: 780
    implicitHeight: layout.implicitHeight + root.topPadding + root.padding

    // The polled services poll while the dashboard exists, and stop with it.
    // Media is watched by its card, which only exists on the home pane.
    Watch {
        service: Brightness
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

            // The clock and date open the calendar, and close it again. The
            // date brightens under the pointer, the way a word to click does.
            Pressable {
                id: dateButton

                Layout.alignment: Qt.AlignBottom
                implicitWidth: clockRow.implicitWidth
                implicitHeight: clockRow.implicitHeight

                Accessible.name: "calendar"

                onClicked: root.togglePane(calendarPane)

                RowLayout {
                    id: clockRow

                    anchors.fill: parent
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
                            color: dateButton.hovered ? Colors.text : Colors.textDim
                        }
                    }
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
                        detailLabel: "show networks"
                        onClicked: Network.setEnabled(!Network.enabled)
                        onDetailClicked: root.pane = networkPane
                    }

                    Tile {
                        Layout.fillWidth: true
                        glyph: Icons.bluetooth(Bluez.enabled, Bluez.connected.length)
                        title: "bluetooth"
                        subtitle: root.bluetoothSubtitle()
                        active: Bluez.enabled
                        detailLabel: "show devices"
                        onClicked: Bluez.setEnabled(!Bluez.enabled)
                        onDetailClicked: root.pane = bluetoothPane
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
                        detailLabel: "show outputs"
                        onMoved: v => Audio.setVolume(v)
                        onToggled: Audio.toggleMuted()
                        onDetailClicked: root.pane = outputPane
                    }

                    SliderRow {
                        Layout.fillWidth: true
                        label: "microphone"
                        glyph: Audio.micMuted ? Glyphs.microphoneOff : Glyphs.microphone
                        value: Audio.micVolume
                        muted: Audio.micMuted
                        detailLabel: "show inputs"
                        onMoved: v => Audio.setMicVolume(v)
                        onToggled: Audio.toggleMicMuted()
                        onDetailClicked: root.pane = inputPane
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

            // As tall as the controls column and no taller. Only the pane on
            // show exists, so only what it shows is polled or scanned.
            Loader {
                id: paneLoader

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: controls.implicitHeight
                Layout.alignment: Qt.AlignTop
                sourceComponent: root.pane
            }
        }

        StatsLine {
            Layout.fillWidth: true
            onProcessesClicked: by => root.showProcesses(by)
            onDisplaysClicked: root.togglePane(displaysPane)
        }
    }

    // Every pane but home has a way back to it.
    Connections {
        target: paneLoader.item
        ignoreUnknownSignals: true

        function onBack(): void {
            root.pane = homePane;
        }
    }

    // Notifications take whatever the media card leaves.
    Component {
        id: homePane

        ColumnLayout {
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

    Component {
        id: networkPane

        NetworkCard {}
    }

    Component {
        id: outputPane

        AudioCard {
            output: true
        }
    }

    Component {
        id: inputPane

        AudioCard {
            output: false
        }
    }

    Component {
        id: calendarPane

        CalendarCard {
            today: root.date
        }
    }

    Component {
        id: processesPane

        ProcessCard {
            sortBy: root.processSort
            onSortPicked: by => root.processSort = by
        }
    }

    Component {
        id: bluetoothPane

        BluetoothCard {}
    }

    Component {
        id: displaysPane

        DisplaysCard {}
    }
}
