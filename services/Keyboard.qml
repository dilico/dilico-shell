pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The keyboard's caps lock, read from its light, which Hyprland keeps in step
// with the key. Read only while watched.
Singleton {
    id: root

    // How many things are showing it, each through a Watch.
    property int watchers: 0

    // Off when there is no light to read: "" is not a number.
    readonly property bool capsLock: parseInt(root.ledText) > 0

    // The light's brightness file, found by name: the input number in it is
    // not stable across boots. "" until found, or if there is none.
    property string ledPath: ""
    property string ledText: ""

    Process {
        running: root.watchers > 0 && root.ledPath === ""
        command: ["sh", "-c", "for f in /sys/class/leds/*::capslock/brightness; do [ -r \"$f\" ] && echo \"$f\" && break; done"]

        stdout: StdioCollector {
            onStreamFinished: root.ledPath = text.trim()
        }
    }

    FileView {
        id: led

        path: root.ledPath
        onLoaded: root.ledText = led.text()
    }

    // The light changes without telling anyone, and sysfs files cannot be
    // watched, so it is read again a few times a second.
    Timer {
        running: root.watchers > 0 && root.ledPath !== ""
        interval: 250
        repeat: true
        onTriggered: led.reload()
    }
}
