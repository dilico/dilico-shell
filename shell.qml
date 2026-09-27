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

    // Space actually reserved from other windows, independent of the surface size.
    exclusiveZone: 38

    // Only the pill takes input; the rest of the surface is click-through.
    mask: Region {
        x: pill.x
        y: pill.y
        width: pill.width
        height: pill.height
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

    Pill {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 5
        label: Qt.formatDateTime(clock.date, "HH:mm · MMM dd")
    }
}
