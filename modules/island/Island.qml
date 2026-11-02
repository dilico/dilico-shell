pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.components
import qs.config
import qs.modules.island.components
import qs.modules.island.panels
import qs.services
import qs.utils

// The black shape at the top edge: a clock pill at rest, the dashboard once
// clicked, the launcher from its key, and the volume, the brightness or the
// workspaces for a moment after one changes. Fills the window; the window's mask decides
// which parts of it take input.
Item {
    id: root

    // Whether the clock is wanted on screen. The window decides, from hover.
    required property bool shown
    required property ShellScreen screen
    required property date date
    // Whether this is the screen the user is on, the one a change of volume,
    // brightness or workspace shows on and the launcher's key opens.
    readonly property bool focused: Compositor.focused(root.screen)
    property bool open: false
    // What the island grows into: "dashboard" from a click on the pill,
    // "launcher" from its key. Kept while it closes, so the panel shrinks
    // away rather than turning into the other. A third panel is the point to
    // split them into Wrapper/Content (conventions §6).
    property string panel: "dashboard"
    readonly property bool typing: root.open && root.panel === "launcher"

    // For a moment after the volume, the brightness or the workspace changes,
    // the pill comes down with it, and with the clock from the clock key. Not
    // over an open panel: the dashboard's sliders already show the levels, a
    // switch with a panel open is the panel's, and the panel has the clock.
    readonly property bool announcing: announceTimer.running

    // What the pill shows instead of the clock: "volume", "brightness",
    // "workspaces", or ""
    // for the clock. Set by a change, the latest one winning; cleared when the
    // pill is wanted for itself, so one that times out leaves still showing
    // what it came down for rather than changing on the way up.
    property string announced: ""

    // Each 0 to 1 as the pill hands over from the clock to it. Animated only
    // while the pill is all the way down; out of sight they jump, so the pill
    // arrives already showing what it came down for. Between the two, one
    // falls as the other rises, so the clock stays out.
    property real volumeProgress: root.announced === "volume" ? 1 : 0
    property real brightnessProgress: root.announced === "brightness" ? 1 : 0
    property real workspacesProgress: root.announced === "workspaces" ? 1 : 0
    readonly property real announceProgress: root.volumeProgress + root.brightnessProgress + root.workspacesProgress

    // The workspace this screen shows, for the dashboard.
    readonly property int workspace: Compositor.workspaceOn(root.screen)

    // 0 is the pill, 1 the open panel. Animated by the state below; every size
    // and opacity derives from it.
    property real progress: 0

    readonly property int pillHeight: 34
    readonly property int pillPadding: 28
    readonly property real clockWidth: Math.round(pillRow.implicitWidth + root.pillPadding)
    // Each width weighted by how far the pill has handed over to it.
    readonly property real pillWidth: Math.round(root.clockWidth * (1 - root.announceProgress)
        + (volumeLevel.implicitWidth + root.pillPadding) * root.volumeProgress
        + (brightnessLevel.implicitWidth + root.pillPadding) * root.brightnessProgress
        + (workspaceStrip.implicitWidth + root.pillPadding) * root.workspacesProgress)

    // The panel is loaded whenever progress is above 0, so these are only
    // ever 0 when progress is too and the size math never reads them.
    readonly property real formWidth: form.implicitWidth
    readonly property real formHeight: form.implicitHeight

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
    // a panel is open or animating, the window takes the whole screen,
    // and what the pill comes down to show takes none, so it never resizes this
    // under the pointer.
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
        if (!root.open)
            root.panel = "dashboard";
        root.open = !root.open;
    }

    // The key again closes it; over the dashboard, it turns into the
    // launcher.
    function toggleLauncher(): void {
        if (root.typing) {
            root.close();
            return;
        }
        root.panel = "launcher";
        root.open = true;
    }

    function close(): void {
        root.open = false;
    }

    // Brings the pill down showing `what`, "volume", "brightness",
    // "workspaces", or "" for the clock, on the screen the user is on. The
    // clock stays long enough to read; a change only long enough to see.
    function announce(what: string): void {
        if (!root.focused || root.blocking)
            return;
        root.announced = what;
        announceTimer.interval = what === "" ? 3000 : 1500;
        announceTimer.restart();
    }

    onAnnouncingChanged: if (!root.announcing && root.shown)
        root.announced = ""
    onShownChanged: if (root.shown && !root.announcing)
        root.announced = ""

    Behavior on volumeProgress {
        enabled: slide.y === 0

        Eased {}
    }

    Behavior on brightnessProgress {
        enabled: slide.y === 0

        Eased {}
    }

    Behavior on workspacesProgress {
        enabled: slide.y === 0

        Eased {}
    }

    Connections {
        target: Audio

        function onAdjusted(): void {
            root.announce("volume");
        }
    }

    Connections {
        target: Brightness

        function onAdjusted(): void {
            root.announce("brightness");
        }
    }

    // How long the pill stays after the last change; each change starts it
    // again, so a held key keeps it down.
    Timer {
        id: announceTimer
    }

    // Escape reaches this once the dashboard has the keyboard, which it gets on
    // demand from the first click inside it; the launcher's field takes Escape
    // itself. The timeout closes a forgotten panel, which would otherwise sit
    // over the windows and swallow clicks.
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.close()
    }

    Connections {
        target: Compositor

        // The key opens it on the screen the user is on.
        function onLauncherPressed(): void {
            if (root.focused)
                root.toggleLauncher();
        }

        function onClockPressed(): void {
            root.announce("");
        }

        // A workspace switch takes the keyboard to a window there, and typing
        // would no longer reach the field. The focus grab does not end on its
        // own then, so the launcher closes with the switch.
        function onFocusedWorkspaceChanged(): void {
            if (root.typing)
                root.close();
        }

        function onWorkspaceSwitched(screen: string): void {
            if (screen === root.screen?.name)
                root.announce("workspaces");
        }
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

        // A MouseArea, not a TapHandler. The panels' controls use
        // TapHandlers, which take only a passive grab on press, and a press
        // that nothing accepts still reaches every TapHandler underneath: a
        // tap on a tile would also tap the backdrop and close the panel.
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
                Eased {}
            }
        }

        // Only consulted while a panel is open, when the shape is still. It
        // sits on the shape itself rather than an item behind it: hover is
        // delivered to what is under the pointer and its ancestors, and an item
        // behind the panel may never hear about it.
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

        // Clips the panel while the shape is still smaller than it.
        Item {
            anchors.fill: parent
            clip: true

            // Swallows clicks on the island's empty space; without it they fall
            // through to the backdrop and close the panel.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            // Hands over to the panel below rather than overlapping it.
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
                    opacity: root.fadeOut(root.announceProgress)
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
                        // A cable over wifi, as NetworkManager prefers it.
                        text: Network.wired ? Glyphs.wired : Icons.wifi(Network.connected, Network.strength)
                        color: Network.wired || Network.enabled ? Colors.textMid : Colors.textFaint
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

                // These hand over with the clock, and with each other, the way
                // the clock does with the panel.
                Level {
                    id: volumeLevel

                    anchors.centerIn: parent
                    glyph: Icons.volume(Audio.muted, Audio.volume)
                    value: Audio.volume
                    muted: Audio.muted
                    opacity: root.fadeIn(root.volumeProgress)
                    visible: opacity > 0
                }

                Level {
                    id: brightnessLevel

                    anchors.centerIn: parent
                    glyph: Glyphs.brightness
                    value: Brightness.level
                    opacity: root.fadeIn(root.brightnessProgress)
                    visible: opacity > 0
                }

                WorkspaceStrip {
                    id: workspaceStrip

                    anchors.centerIn: parent
                    workspaces: Compositor.workspacesOn(root.screen)
                    opacity: root.fadeIn(root.workspacesProgress)
                    visible: opacity > 0
                }
            }

            // Exists only while open or animating, so its polling stops when
            // the island is a pill again.
            Loader {
                id: form

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                active: root.blocking
                opacity: root.fadeIn(root.progress)
                sourceComponent: root.panel === "launcher" ? launcher : dashboard
            }
        }
    }

    Component {
        id: dashboard

        Dashboard {
            date: root.date
            workspace: root.workspace
        }
    }

    Component {
        id: launcher

        Launcher {
            onLaunched: root.close()
            onCancelled: root.close()
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

    // How the pill slides and hands over between what it shows.
    component Eased: NumberAnimation {
        duration: Animations.durationMedium
        easing.type: Animations.easingType
    }
}
