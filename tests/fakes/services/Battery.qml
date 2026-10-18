pragma Singleton

import QtQuick
import Quickshell

// Stands in for services/Battery in tests.
Singleton {
    property bool available: true
    property real level: 0.86
}
