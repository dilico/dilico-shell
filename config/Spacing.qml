pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Between a card's edge and what it holds. The media and notification
    // cards stand one above the other, so their contents line up.
    readonly property int card: 12
}
