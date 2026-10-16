pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Material Design (Nerd Fonts nf-md-*), each rendered from the installed
    // JetBrainsMono Nerd Font before being added.
    readonly property string wifi1: String.fromCodePoint(0xf091f)
    readonly property string wifi2: String.fromCodePoint(0xf0922)
    readonly property string wifi3: String.fromCodePoint(0xf0925)
    readonly property string wifi4: String.fromCodePoint(0xf0928)
    readonly property string wifiOff: String.fromCodePoint(0xf05aa)
    readonly property string bluetooth: String.fromCodePoint(0xf00af)
    readonly property string bluetoothOff: String.fromCodePoint(0xf00b2)
    readonly property string bluetoothConnected: String.fromCodePoint(0xf00b1)
    readonly property string coffee: String.fromCodePoint(0xf0176)
    readonly property string coffeeOff: String.fromCodePoint(0xf0faa)
    readonly property string airplane: String.fromCodePoint(0xf001d)
    readonly property string airplaneOff: String.fromCodePoint(0xf001e)
    readonly property string volume: String.fromCodePoint(0xf057e)
    readonly property string volumeLow: String.fromCodePoint(0xf0580)
    readonly property string volumeOff: String.fromCodePoint(0xf0581)
    readonly property string microphone: String.fromCodePoint(0xf036c)
    readonly property string microphoneOff: String.fromCodePoint(0xf036d)
    // white_balance_sunny: a disc with separate rays. brightness_6 (0xf00e0)
    // has a toothed ring and reads as a cog at this size.
    readonly property string brightness: String.fromCodePoint(0xf05a8)
    readonly property string lock: String.fromCodePoint(0xf033e)
    readonly property string logout: String.fromCodePoint(0xf0343)
    readonly property string restart: String.fromCodePoint(0xf0709)
    readonly property string power: String.fromCodePoint(0xf0425)
    readonly property string play: String.fromCodePoint(0xf040a)
    readonly property string pause: String.fromCodePoint(0xf03e4)
    readonly property string next: String.fromCodePoint(0xf04ad)
    readonly property string previous: String.fromCodePoint(0xf04ae)
}
