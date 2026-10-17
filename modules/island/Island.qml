pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.components
import qs.config
import qs.modules.island.components
import qs.modules.island.panels
import qs.services
import qs.utils

// The black shape at the top edge: a clock pill at rest, the dashboard once
// clicked, and the volume for a moment after it changes. Fills the window; the
// window's mask decides which parts of it take input.
Item {
    id: root

    // Whether the clock is wanted on screen. The window decides, from hover.
    required property bool shown
    // Whether this is the screen the user is on, the one a change of volume
    // shows on.
    required property bool focused
    required property date date
    property bool open: false

    // For a moment after the volume changes, the pill comes down with it. Not
    // over the dashboard, whose slider already shows it.
    readonly property bool announcing: announceTimer.running

    // The volume rather than the clock in the pill. Set by a change; cleared
    // when the pill is wanted for itself, so one that times out leaves with
    // the volume still showing rather than changing on the way up.
    property bool volumeShown: false

    // 0 the clock, 1 the volume, in the pill. Animated only while the pill is
    // all the way down; out of sight it jumps, so the pill arrives already
    // showing what it came down for.
    property real volumeProgress: root.volumeShown ? 1 : 0

    // 0 is the pill, 1 the dashboard. Animated by the state below; every size
    // and opacity derives from it.
    property real progress: 0

    readonly property int pillHeight: 34
    readonly property int pillPadding: 28
    readonly property real clockWidth: Math.round(pillRow.implicitWidth + root.pillPadding)
    readonly property real volumeWidth: volumeLevel.implicitWidth + root.pillPadding
    readonly property real pillWidth: Math.round(root.clockWidth + (root.volumeWidth - root.clockWidth) * root.volumeProgress)

    // The dashboard is loaded whenever progress is above 0, so these are only
    // ever 0 when progress is too and the size math never reads them.
    readonly property real formWidth: dashboard.implicitWidth
    readonly property real formHeight: dashboard.implicitHeight

    // How the island meets the top edge; see config/Appearance. A notch sits on
    // the edge and reaches one fillet past each side; a pill floats `gap`
    // below it and stops at its own edges.
    readonly property int gap: Appearance.attached ? 0 : Appearance.gap
    readonly property int flare: Appearance.attached ? Rounding.window : 0

    // From the click that opens it until the close animation ends, the island
    // takes the whole screen's input, so a click anywhere else lands on the
    // backdrop and closes it.
    readonly property bool blocking: root.open || root.progress > 0

    // Where the resting pill takes input, measured from the top edge, so it
    // covers a notch's fillets and the gap above a pill. Only the clock: while
    // the dashboard is open or animating, the window takes the whole screen,
    // and the volume takes none, so it never resizes this under the pointer.
    readonly property rect hitArea: Qt.rect(Math.round((root.width - root.clockWidth) / 2) - root.flare, 0, root.clockWidth + root.flare * 2, root.gap + root.pillHeight)

    // A notch's outline as an SVG path, in a frame that starts one fillet to the
    // left of the island: a concave fillet down from the screen edge, the left
    // side, the rounded bottom, the right side, and a fillet back up. Open
    // along the top, the screen edge, so the border has no line there.
    //
    // `inset` moves every part of it into the island by that much. The fill
    // takes 0; the 1 px border takes 0.5, which puts it on a whole pixel inside
    // the edge instead of blurring across two.
    function notchPath(width: real, height: real, inset: real): string {
        const r = Rounding.window;
        const i = inset;
        const fillet = r + i;
        const corner = r - i;
        return `M 0 ${-i}`
            + ` A ${fillet} ${fillet} 0 0 1 ${r + i} ${r}`
            + ` L ${r + i} ${height - r}`
            + ` A ${corner} ${corner} 0 0 0 ${2 * r} ${height - i}`
            + ` L ${width} ${height - i}`
            + ` A ${corner} ${corner} 0 0 0 ${width + r - i} ${height - r}`
            + ` L ${width + r - i} ${r}`
            + ` A ${fillet} ${fillet} 0 0 1 ${width + 2 * r} ${-i}`;
    }

    // A hand-over between two things in one slot, as p goes 0 to 1: the
    // first reaches 0 before the second leaves it (conventions §7).
    function fadeOut(p: real): real {
        return Math.max(0, 1 - p * 2);
    }

    function fadeIn(p: real): real {
        return Math.max(0, p * 2 - 1);
    }

    function toggle(): void {
        root.open = !root.open;
    }

    function close(): void {
        root.open = false;
    }

    onAnnouncingChanged: root.volumeShown = root.announcing || !root.shown
    onShownChanged: if (root.shown && !root.announcing)
        root.volumeShown = false

    Behavior on volumeProgress {
        enabled: slide.y === 0

        NumberAnimation {
            duration: Animations.durationMedium
            easing.type: Animations.easingType
        }
    }

    Connections {
        target: Audio

        function onAdjusted(): void {
            if (root.focused && !root.blocking)
                announceTimer.restart();
        }
    }

    // How long the volume stays after the last change; each change starts it
    // again, so a held key keeps it down.
    Timer {
        id: announceTimer

        interval: 1500
    }

    // Escape reaches this once the dashboard has the keyboard, which it gets on
    // demand from the first click inside it. The timeout closes a forgotten
    // dashboard, which would otherwise sit over the windows and swallow clicks.
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.close()
    }

    // Held while a network password is asked for: typing it needs no pointer
    // on the island, and a backdrop click still closes it.
    Timer {
        running: root.open && !overIsland.hovered && !Network.needsPassword
        interval: 30000
        onTriggered: root.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.backdrop
        opacity: root.progress
        visible: root.blocking

        // A MouseArea, not a TapHandler. The dashboard's controls use
        // TapHandlers, which take only a passive grab on press, and a press
        // that nothing accepts still reaches every TapHandler underneath: a
        // tap on a tile would also tap the backdrop and close the dashboard.
        // A MouseArea only sees presses no item above it has accepted, and the
        // island's catcher accepts all of those.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.close()
        }
    }

    Item {
        id: island

        x: Math.round((root.width - island.width) / 2)
        y: root.gap
        width: Math.round(root.pillWidth + (root.formWidth - root.pillWidth) * root.progress)
        height: Math.round(root.pillHeight + (root.formHeight - root.pillHeight) * root.progress)

        // Slides up past the top edge rather than fading in place.
        transform: Translate {
            id: slide

            y: root.shown || root.announcing ? 0 : -(island.y + island.height)

            Behavior on y {
                NumberAnimation {
                    duration: Animations.durationMedium
                    easing.type: Animations.easingType
                }
            }
        }

        // Only consulted while the dashboard is open, when the shape is still.
        // It sits on the shape itself rather than an item behind it: hover is
        // delivered to what is under the pointer and its ancestors, and an item
        // behind the dashboard may never hear about it.
        HoverHandler {
            id: overIsland
        }

        // A pill is a plain rounded rectangle; its border is drawn inside the
        // edge, which keeps it on whole pixels.
        Rectangle {
            anchors.fill: parent
            visible: !Appearance.attached
            radius: Rounding.window
            color: Colors.island
            border.width: 1
            border.color: Colors.outline
        }

        // A notch is one path, so its border can follow the fillets up into
        // the screen edge. The paths are only built for a notch: they are
        // rebuilt on every frame of the open and close animation.
        Shape {
            x: -root.flare
            width: island.width + root.flare * 2
            height: island.height
            visible: Appearance.attached
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Colors.island
                strokeColor: "transparent"
                strokeWidth: 0

                PathSvg {
                    path: Appearance.attached ? `${root.notchPath(island.width, island.height, 0)} Z` : ""
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Colors.outline
                strokeWidth: 1

                PathSvg {
                    path: Appearance.attached ? root.notchPath(island.width, island.height, 0.5) : ""
                }
            }
        }

        // Clips the dashboard while the shape is still smaller than it.
        Item {
            anchors.fill: parent
            clip: true

            // Swallows clicks on the island's empty space; without it they fall
            // through to the backdrop and close the dashboard.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            // Hands over to the dashboard below rather than overlapping it.
            Pressable {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: root.pillWidth
                height: root.pillHeight
                opacity: root.fadeOut(root.progress)
                visible: opacity > 0

                Accessible.name: "open dashboard"

                onClicked: root.toggle()

                Row {
                    id: pillRow

                    anchors.centerIn: parent
                    spacing: 10
                    opacity: root.fadeOut(root.volumeProgress)
                    visible: opacity > 0

                    Subtext {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Format.date(root.date, "ddd dd")
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Format.time(root.date)
                        font.weight: Font.DemiBold
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icons.wifi(Network.connected, Network.strength)
                        color: Network.enabled ? Colors.textMid : Colors.textFaint
                    }

                    Subtext {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Battery.available
                        text: Format.percent(Battery.level)
                    }

                    // Something is waiting in the dashboard.
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Notifications.count > 0
                        width: 6
                        height: 6
                        radius: 1
                        color: Colors.text
                    }
                }

                // Hands over with the clock the way the clock does with the
                // dashboard.
                VolumeLevel {
                    id: volumeLevel

                    anchors.centerIn: parent
                    value: Audio.volume
                    muted: Audio.muted
                    opacity: root.fadeIn(root.volumeProgress)
                    visible: opacity > 0
                }
            }

            // Exists only while open or animating, so its polling stops when
            // the island is a pill again.
            Loader {
                id: dashboard

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                active: root.blocking
                opacity: root.fadeIn(root.progress)

                sourceComponent: Dashboard {
                    date: root.date
                }
            }
        }
    }

    states: State {
        name: "open"
        when: root.open

        PropertyChanges {
            root.progress: 1
        }
    }

    transitions: Transition {
        NumberAnimation {
            property: "progress"
            duration: Animations.durationLong
            easing.type: Animations.easingType
        }
    }
}
