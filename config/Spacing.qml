pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Between a card's edge and what it holds. The media and notification
    // cards stand one above the other, so their contents line up.
    readonly property int card: 12

    // How far a list sits in from its card's edge. The notification and
    // network lists stand in the same place, so their rows line up.
    readonly property int list: 6
}
