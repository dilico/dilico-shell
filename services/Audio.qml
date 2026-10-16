pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0

    readonly property bool micMuted: root.source?.audio?.muted ?? false
    readonly property real micVolume: root.source?.audio?.volume ?? 0

    function setVolume(v: real): void {
        root.setNodeVolume(root.sink, v);
    }

    function toggleMuted(): void {
        root.toggleNodeMuted(root.sink);
    }

    function setMicVolume(v: real): void {
        root.setNodeVolume(root.source, v);
    }

    function toggleMicMuted(): void {
        root.toggleNodeMuted(root.source);
    }

    // Moving a slider is a request to hear it, so it unmutes as it sets.
    function setNodeVolume(node: var, v: real): void {
        if (!node?.audio)
            return;
        node.audio.muted = false;
        node.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleNodeMuted(node: var): void {
        if (!node?.audio)
            return;
        node.audio.muted = !node.audio.muted;
    }

    // Volume and mute stay empty on an untracked node.
    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n)
    }
}
