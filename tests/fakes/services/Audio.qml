pragma Singleton

import QtQuick
import Quickshell

// Stands in for services/Audio in tests: the same interface as far as the
// output and input lists use it, recording what was asked instead of asking
// PipeWire. A test node is a QtObject with nickname, isSink, kind, where and
// audio ({ volume, muted }).
Singleton {
    id: root

    property int watchers: 0
    property bool muted: false
    property bool micMuted: false
    property bool listsReady: true
    property var sink: null
    property var source: null
    // What offered() returns for each.
    property var outputs: []
    property var inputs: []
    // Each request as [name, argument]; reset by tests.
    property var calls: []

    function offered(outputs: bool): var {
        return outputs ? root.outputs : root.inputs;
    }

    function inUse(node: var): bool {
        return node !== null && (node === root.sink || node === root.source);
    }

    function name(node: var): string {
        return node?.nickname ?? "";
    }

    function kind(node: var): string {
        return node?.kind ?? "speaker";
    }

    function where(node: var): string {
        return node?.where ?? "";
    }

    function toggleMuted(): void {
        root.calls.push(["toggleMuted", ""]);
    }

    function toggleMicMuted(): void {
        root.calls.push(["toggleMicMuted", ""]);
    }

    function select(node: var): void {
        root.calls.push(["select", node.nickname]);
    }
}
