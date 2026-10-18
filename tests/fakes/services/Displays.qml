pragma Singleton

import QtQuick
import Quickshell
import qs.utils

// Stands in for services/Displays in tests: the same interface as far as the
// displays pane uses it. A test monitor is shaped as the service's are.
Singleton {
    id: root

    property int watchers: 0
    property var monitors: []
    readonly property var layout: Arrange.rects(root.monitors)
    property bool pending: false
    property int secondsLeft: 0
    // Each request as [name, ...arguments]; reset by tests.
    property var calls: []

    function move(name: string, x: real, y: real): void {
        root.calls.push(["move", name, x, y]);
    }

    function setMode(name: string, mode: var): void {
        root.calls.push(["setMode", name, mode]);
    }

    function keep(): void {
        root.calls.push(["keep"]);
    }

    function revert(): void {
        root.calls.push(["revert"]);
    }
}
