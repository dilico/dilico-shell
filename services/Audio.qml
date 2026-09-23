pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // Set true by a consumer that is currently showing output availability, so
    // route probing only runs while something is looking at it.
    property bool watchRoutes: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0

    // Candidate outputs, independent of anything PwObjectTracker populates.
    // Filtering this list on tracked properties would feed the tracker from its
    // own output and loop until the shell crashes.
    readonly property var audioNodes: Pipewire.nodes.values
        .filter(n => n.isSink && !n.isStream)

    // Outputs worth offering: audio-capable, and not a dead port.
    readonly property var sinks: root.audioNodes
        .filter(n => n.audio && root.available(n))
        .sort((a, b) => root.shortName(a).localeCompare(root.shortName(b), undefined, {
            numeric: true
        }))

    property var routeAvailability: ({})
    property string routeSignature: ""
    property bool settled: false

    // Volume or mute changed from outside the shell: media keys, wpctl, another app.
    signal changedExternally()

    onVolumeChanged: if (root.settled && !selfChange.running) root.changedExternally()
    onMutedChanged: if (root.settled && !selfChange.running) root.changedExternally()
    onAudioNodesChanged: root.refreshRoutes()

    function setVolume(v: real): void {
        if (!root.sink?.audio)
            return;
        selfChange.restart();
        root.sink.audio.muted = false;
        root.sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMuted(): void {
        if (!root.sink?.audio)
            return;
        root.sink.audio.muted = !root.sink.audio.muted;
    }

    function setSink(node: var): void {
        // defaultAudioSink is read-only; it follows once PipeWire confirms.
        Pipewire.preferredDefaultAudioSink = node;
    }

    function refreshRoutes(): void {
        if (!routeProbe.running)
            routeProbe.running = true;
    }

    function readRoutes(json: string): void {
        const map = {};
        for (const obj of JSON.parse(json)) {
            const routes = obj.info?.params?.EnumRoute;
            if (!routes)
                continue;
            for (const route of routes)
                for (const dev of route.devices ?? [])
                    map[`${obj.id}:${dev}`] = route.available !== "no";
        }

        // Rebuilding this unchanged would recreate every list delegate on a timer.
        const signature = JSON.stringify(map);
        if (signature === root.routeSignature)
            return;
        root.routeSignature = signature;
        root.routeAvailability = map;
    }

    function shortName(node: var): string {
        if (!node)
            return "No output";
        // nickname is "Speaker" or "HDMI 1" where description is the full
        // controller name; it comes back empty rather than null when unset.
        return node.nickname || node.description || node.name;
    }

    // Fails open: a node shows unless a route says it is unavailable, so an
    // unprobed or route-less device is never lost.
    function available(node: var): bool {
        const props = node.properties;
        const key = `${props["device.id"]}:${props["card.profile.device"]}`;
        return root.routeAvailability[key] !== false;
    }

    PwObjectTracker {
        objects: root.audioNodes
    }

    // PipeWire populates volume shortly after startup; without this the first
    // real value would look like an external change and pop up an OSD at login.
    Timer {
        interval: 1000
        running: true
        onTriggered: root.settled = true
    }

    // Suppresses changedExternally for our own writes, including the confirmation
    // PipeWire sends back a moment later.
    Timer {
        id: selfChange

        interval: 300
    }

    // Route availability lives on the device, not the node, and Quickshell's
    // Pipewire service exposes only nodes — so it has to come from pw-dump.
    Process {
        id: routeProbe

        command: ["pw-dump"]

        stdout: StdioCollector {
            onStreamFinished: root.readRoutes(text)
        }
    }

    // Plugging a cable changes availability without adding or removing nodes,
    // so there is no signal to hang this on.
    Timer {
        running: root.watchRoutes
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshRoutes()
    }
}
