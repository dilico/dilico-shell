pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Material Design (Nerd Fonts nf-md-*)
    readonly property string volume: String.fromCodePoint(0xf057e)
    readonly property string volumeMedium: String.fromCodePoint(0xf0580)
    readonly property string volumeOff: String.fromCodePoint(0xf0581)
    readonly property string network: String.fromCodePoint(0xf05a9)
    readonly property string ethernet: String.fromCodePoint(0xf0200)
    readonly property string battery: String.fromCodePoint(0xf0079)
    readonly property string batteryCharging: String.fromCodePoint(0xf0084)
    readonly property string bluetooth: String.fromCodePoint(0xf00af)
    readonly property string brightness: String.fromCodePoint(0xf00e0)
    readonly property string settings: String.fromCodePoint(0xf0493)
    readonly property string power: String.fromCodePoint(0xf0425)
    readonly property string chevronDown: String.fromCodePoint(0xf0140)
    readonly property string chevronUp: String.fromCodePoint(0xf0143)
    readonly property string check: String.fromCodePoint(0xf012c)
}
