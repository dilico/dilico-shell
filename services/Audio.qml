pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.utils

Singleton {
    id: root

    // How many things are showing the output or input list, each through a
    // Watch. Which ports have something plugged in is only checked meanwhile.
    property int watchers: 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0

    readonly property bool micMuted: root.source?.audio?.muted ?? false
    readonly property real micVolume: root.source?.audio?.volume ?? 0

    // Every audio device, whatever its state. Filtering this on anything the
    // tracker below fills in would feed the tracker from its own output, a
    // binding loop that crashed the shell once (conventions §10); whether a
    // node is a stream, and whether it carries audio, are fixed when it
    // appears, so they are safe.
    readonly property var audioDevices: Pipewire.nodes.values.filter(n => !n.isStream && n.audio)

    // Which ports have nothing plugged in, keyed "<device id>:<port>", or
    // null before the first reading. Kept between lists, so only the first
    // one waits for it.
    property var unplugged: null

    // Whether the lists are complete: the ports have been read, and every
    // device's properties, which say which port it is, have arrived. Before
    // that a list would show ports it is about to hide.
    readonly property bool listsReady: root.unplugged !== null && root.audioDevices.every(n => n.ready)

    // The output in use was turned up, down, muted or unmuted: a volume key,
    // the dashboard, another app. Not when the output itself changes, nor when
    // it first reports.
    signal adjusted()

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

    // The outputs, or else the inputs, worth offering: devices with something
    // plugged in, the one in use first, then by name. A port shows unless
    // PipeWire says nothing is plugged into it, so one that cannot tell is
    // never lost.
    function offered(outputs: bool): var {
        return root.audioDevices.filter(n => n.isSink === outputs && n.ready && !root.unplugged?.[root.port(n)]).sort((a, b) => Order.first(root.inUse(a), root.inUse(b)) || Order.byName(root.name(a), root.name(b)));
    }

    function inUse(node: var): bool {
        return node !== null && (node === root.sink || node === root.source);
    }

    function port(node: var): string {
        const props = node?.properties ?? {};
        return `${props["device.id"]}:${props["card.profile.device"]}`;
    }

    // "Speaker" or "HDMI 1", where the description is the controller's full
    // name; nickname comes back empty rather than null when unset.
    function name(node: var): string {
        return node?.nickname || node?.description || node?.name || "";
    }

    // What sort of thing it is, in names Glyphs has an entry under.
    function kind(node: var): string {
        const props = node?.properties ?? {};
        const label = `${node?.nickname ?? ""} ${props["device.profile.name"] ?? ""}`.toLowerCase();
        if (/hdmi|displayport/.test(label))
            return "display";
        if (/headphone/.test(label))
            return "headphones";
        if (/headset/.test(label) || props["device.api"] === "bluez5")
            return node?.isSink ? "headphones" : "headset";
        return node?.isSink ? "speaker" : "microphone";
    }

    // Where it is, in words, or "".
    function where(node: var): string {
        const props = node?.properties ?? {};
        if (props["device.api"] === "bluez5")
            return "bluetooth";
        switch (props["device.bus"]) {
        case "pci":
            return "built-in";
        case "usb":
            return "usb";
        }
        return "";
    }

    // Makes it the output or input in use. The default follows once PipeWire
    // confirms it.
    function select(node: var): void {
        if (!node)
            return;
        if (node.isSink)
            Pipewire.preferredDefaultAudioSink = node;
        else
            Pipewire.preferredDefaultAudioSource = node;
    }

    // Each card's routes are the ports its nodes play to or record from, with
    // whether anything is plugged into them. An unchanged reading is not
    // stored, so it does not rebuild the lists.
    function readRoutes(json: string): void {
        const map = {};
        for (const card of JSON.parse(json)) {
            for (const route of card.info?.params?.EnumRoute ?? []) {
                if (route.available !== "no")
                    continue;
                for (const port of route.devices ?? [])
                    map[`${card.id}:${port}`] = true;
            }
        }
        if (JSON.stringify(map) !== JSON.stringify(root.unplugged))
            root.unplugged = map;
    }

    // Bound to the output in use once it has reported, so a switch or a first
    // report moves the target rather than emitting.
    Connections {
        target: root.sink?.ready ? root.sink.audio : null

        function onVolumesChanged(): void {
            root.adjusted();
        }

        function onMutedChanged(): void {
            root.adjusted();
        }
    }

    // Volume and mute, and the properties that say which port a device is,
    // stay empty on an untracked node. Tracking is a subscription, not a
    // poll, so every device stays tracked, the defaults among them: a list
    // opens on loaded devices.
    PwObjectTracker {
        objects: root.audioDevices
    }

    // Whether a port has something plugged in lives on the card, not the
    // node, and Quickshell's PipeWire service exposes only nodes. Only the
    // cards are dumped.
    Process {
        id: routeReader

        command: ["pw-dump", "Device"]

        stdout: StdioCollector {
            onStreamFinished: root.readRoutes(text)
        }
    }

    // Plugging in a cable changes a route without adding or removing a node,
    // so there is no signal to wait for.
    Timer {
        running: root.watchers > 0
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: routeReader.running = true
    }
}
