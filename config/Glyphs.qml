pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Material Design (Nerd Fonts nf-md-*)
    readonly property string volume: String.fromCodePoint(0xf057e)
    readonly property string volumeMedium: String.fromCodePoint(0xf0580)
    readonly property string volumeOff: String.fromCodePoint(0xf0581)
    readonly property string speaker: String.fromCodePoint(0xf04c3)
    readonly property string headphones: String.fromCodePoint(0xf02cb)
    readonly property string monitor: String.fromCodePoint(0xf0379)
    readonly property string network: String.fromCodePoint(0xf05a9)
    readonly property string networkOff: String.fromCodePoint(0xf05aa)
    readonly property string networkStrength1: String.fromCodePoint(0xf091f)
    readonly property string networkStrength2: String.fromCodePoint(0xf0922)
    readonly property string networkStrength3: String.fromCodePoint(0xf0925)
    readonly property string networkStrength4: String.fromCodePoint(0xf0928)
    readonly property string lock: String.fromCodePoint(0xf033e)
    readonly property string ethernet: String.fromCodePoint(0xf0200)
    readonly property string battery: String.fromCodePoint(0xf0079)
    readonly property string batteryCharging: String.fromCodePoint(0xf0084)
    readonly property string bluetooth: String.fromCodePoint(0xf00af)
    readonly property string coffee: String.fromCodePoint(0xf0176)
    readonly property string coffeeOff: String.fromCodePoint(0xf0faa)
    readonly property string brightness: String.fromCodePoint(0xf00e0)
    readonly property string settings: String.fromCodePoint(0xf0493)
    readonly property string power: String.fromCodePoint(0xf0425)
    readonly property string refresh: String.fromCodePoint(0xf0450)
}
