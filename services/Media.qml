pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // How many things are showing the position, each through a Watch. MPRIS
    // does not push position, so it is only re-read while something is looking.
    property int watchers: 0

    readonly property var players: Mpris.players.values

    // The one making sound, else whichever is first. Browsers register a player
    // per tab, so "first" alone would often pick a silent one.
    readonly property var player: root.players.find(p => p.isPlaying) ?? root.players[0] ?? null

    readonly property bool available: root.player !== null
    readonly property bool playing: root.player?.isPlaying ?? false
    readonly property string title: root.player?.trackTitle || root.player?.identity || ""
    readonly property string artist: root.player?.trackArtist ?? ""
    readonly property string artUrl: root.player?.trackArtUrl ?? ""
    readonly property bool canGoNext: root.player?.canGoNext ?? false
    readonly property bool canGoPrevious: root.player?.canGoPrevious ?? false

    // Seconds.
    readonly property real position: root.player?.position ?? 0
    readonly property real length: root.player?.lengthSupported ? root.player.length : 0
    readonly property real progress: root.length > 0 ? Math.min(1, root.position / root.length) : 0

    function togglePlaying(): void {
        if (root.player?.canTogglePlaying)
            root.player.togglePlaying();
    }

    function next(): void {
        if (root.canGoNext)
            root.player.next();
    }

    function previous(): void {
        if (root.canGoPrevious)
            root.player.previous();
    }

    // Quickshell re-reads position when the signal is emitted.
    Timer {
        running: root.watchers > 0 && root.playing
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }
}
