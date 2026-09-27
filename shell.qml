import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.bar
import qs.services

// qmllint disable uncreatable-type
// False positive: PanelWindow is creatable from QML, but qmllint reads its C++
// registration as uncreatable.
PanelWindow {
    id: panel

    // How close to the top edge the pointer has to come for the pill to appear.
    // Thin enough that it barely intrudes on the window below; the screen edge
    // stops the pointer, so flicking up hits it.
    readonly property int revealMargin: 3

    // Once the pill is up, a much taller band keeps it up. The pill appears
    // centred and the pointer arrives anywhere along the edge, so it needs room
    // to travel without the trigger sliding out from under it.
    readonly property int keepMargin: 48

    readonly property int hoverMargin: panel.revealed ? panel.keepMargin : panel.revealMargin

    // The pill stays hidden until the pointer asks for it, or until it has a
    // reason of its own to be up: an open panel, or an OSD.
    readonly property bool wanted: proximity.hovered || pill.open

    // hideTimer delays only the way out, so the pill survives a pointer that
    // strays off the band for a moment.
    readonly property bool revealed: panel.wanted || hideTimer.running

    onWantedChanged: if (!panel.wanted)
        hideTimer.restart()

    anchors {
        top: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "quickshell:bar"

    // Taken only while a panel needs typing, so the bar never steals the
    // keyboard from the focused window at any other time.
    WlrLayershell.keyboardFocus: pill.wantsKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"

    // Constant: the surface must never resize while the bar is in use.
    implicitHeight: pill.anchors.topMargin + pill.maxHeight

    // Nothing is reserved: windows get the whole screen and the pill floats over
    // them when called up.
    exclusiveZone: 0

    // The band along the top edge always takes input, since it is what the
    // pointer enters to call the pill up. The pill joins it only while showing,
    // so a hidden one never swallows a click. The rest is click-through.
    mask: Region {
        item: band

        Region {
            x: pill.x
            y: pill.y
            width: panel.revealed ? pill.width : 0
            height: panel.revealed ? pill.height : 0
        }
    }

    // Stops the compositor reporting idle, so hypridle never fires its timers.
    IdleInhibitor {
        window: panel
        enabled: Idle.inhibited
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    // The pointer being in here is what counts as near the top edge. The mask is
    // taken from it, so the region that takes input and the one that reveals the
    // pill can never disagree.
    Item {
        id: band

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: panel.hoverMargin

        HoverHandler {
            id: proximity
        }
    }

    Timer {
        id: hideTimer

        interval: 500
    }

    Pill {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // Constant, so the window never resizes with the reveal.
        anchors.topMargin: 5
        label: Qt.formatDateTime(clock.date, "HH:mm · MMM dd")
        shown: panel.revealed
    }
}
