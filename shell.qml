import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.island
import qs.services

// qmllint disable uncreatable-type
// False positive: PanelWindow is creatable from QML, but qmllint reads its C++
// registration as uncreatable.
PanelWindow {
    id: panel

    // How close to the top edge the pointer has to come for the clock to drop
    // down. The screen edge stops the pointer, so flicking up hits it.
    readonly property int revealMargin: 3

    // Once the clock is down, a margin around the notch keeps it there, so a
    // pointer that slips just off its edge does not send it away. Only the
    // notch and this margin take input; the rest of the top of the screen
    // stays clickable.
    readonly property int keepPad: 16

    // The resting pill's hit area plus that margin, measured from the top edge.
    readonly property rect keepArea: Qt.rect(island.hitArea.x - panel.keepPad, 0, island.hitArea.width + panel.keepPad * 2, island.hitArea.height + panel.keepPad)

    // Where the pointer was last seen over the window.
    readonly property point pointer: inside.point.position

    // Whether that was in the strip along the edge, or in the margin around
    // the resting pill.
    readonly property bool inStrip: panel.pointer.y < panel.revealMargin
    readonly property bool inKeepArea: panel.pointer.x >= panel.keepArea.x && panel.pointer.x < panel.keepArea.x + panel.keepArea.width && panel.pointer.y < panel.keepArea.height

    // Hovered is not enough on its own. While the dashboard is open the mask
    // is the whole screen, so the pointer is inside wherever it is; when the
    // dashboard closes the mask shrinks out from under it, and Hyprland
    // reports no leave until the pointer moves, so hovered would stay true
    // and hold the clock down. Where the pointer was last seen still says
    // whether it is in what the mask has kept.
    readonly property bool wanted: island.blocking || inside.hovered && (panel.inStrip || panel.inKeepArea)

    // hideTimer delays only the way out, so the clock survives a pointer that
    // strays off the band for a moment.
    readonly property bool revealed: panel.wanted || hideTimer.running

    onWantedChanged: if (!panel.wanted)
        hideTimer.restart()

    // A singleton is only created on first reference, which would otherwise be
    // whenever something first reads it. The notification daemon has to be up
    // from login; the backlight takes its one reading before the dashboard is
    // first opened (see Brightness).
    Component.onCompleted: {
        Notifications.count;
        Brightness.available;
    }

    // The whole screen, so the dashboard's backdrop can catch a click anywhere.
    // The size never changes; the mask decides what takes input.
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "quickshell:dilico"
    WlrLayershell.layer: WlrLayer.Overlay

    // On demand, and only while the dashboard is open: the keyboard comes here
    // once something in the dashboard is clicked, which is what makes Escape
    // work. Never Exclusive. An exclusive surface keeps every window from
    // taking focus, so after a workspace switch Hyprland still remembers a
    // window on the old one, and hands focus back to it, workspace and all,
    // the moment the dashboard lets go.
    WlrLayershell.keyboardFocus: island.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    color: "transparent"
    exclusiveZone: 0

    // The strip along the top always takes input, since it is what the pointer
    // enters to call the clock down. The notch and its margin join it only
    // while showing, and the whole screen only while the dashboard is open.
    // Everything else clicks through to the windows below.
    //
    // The margin wraps the resting pill's hit area, which hover never changes,
    // so this region cannot resize under the pointer.
    mask: Region {
        width: panel.width
        height: panel.revealMargin

        Region {
            x: panel.keepArea.x
            width: panel.revealed ? panel.keepArea.width : 0
            height: panel.revealed ? panel.keepArea.height : 0
        }

        Region {
            width: island.blocking ? panel.width : 0
            height: island.blocking ? panel.height : 0
        }
    }

    // Stops the compositor reporting idle, so hypridle never fires its timers.
    IdleInhibitor {
        window: panel
        enabled: Idle.inhibited
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // Long enough to carry the pointer from wherever it touched the edge down
    // to the notch: once it leaves the 3 px strip, only this keeps the clock up
    // until it arrives.
    Timer {
        id: hideTimer

        interval: 800
    }

    Island {
        id: island

        anchors.fill: parent
        shown: panel.revealed
        date: clock.date

        // On the island, which fills the window and holds everything else.
        // Qt delivers hover to the topmost item under the pointer and that
        // item's ancestors, so a handler here hears every hover without
        // taking it from the controls. On an item laid over the top it would
        // be the topmost item itself, and no control would ever be hovered:
        // no hand cursor, no highlight.
        HoverHandler {
            id: inside
        }
    }
}
