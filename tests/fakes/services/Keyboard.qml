pragma Singleton

import QtQuick
import Quickshell

// Stands in for services/Keyboard in tests.
Singleton {
    property int watchers: 0
    property bool capsLock: false
}
