pragma Singleton

import QtQuick
import Quickshell

// Stands in for services/Processes in tests: the same interface as far as the
// processes pane uses it. A test process is { pid, name, cpu, memory }.
Singleton {
    id: root

    property int watchers: 0
    property bool ready: true
    property var processes: []
    // Each request as [name, argument]; reset by tests.
    property var calls: []

    function end(pid: int, force: bool): void {
        root.calls.push([force ? "kill" : "end", pid]);
    }

    function top(by: string, count: int): var {
        return root.processes.slice().sort((a, b) => b[by] - a[by]).slice(0, count);
    }
}
