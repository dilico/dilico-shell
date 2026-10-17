pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import qs.utils

// Wifi through NetworkManager, and the one attempt at joining a network that
// can be under way at a time. NetworkManager's quirks around joining are all
// absorbed here, so the list that shows it stays declarative.
Singleton {
    id: root

    // How many things are showing the network list, each through a Watch. The
    // radio only scans while something is looking: scanning costs radio time.
    property int watchers: 0

    // The network being joined, from the click until it connects or the
    // attempt is given up, or null. Kept past a failure so the failure shows
    // against it.
    property var joining: null
    // Whether a password has to be typed before the next try.
    property bool needsPassword: false
    // From a password being sent until NetworkManager answers.
    property bool busy: false
    // Why the last try failed, ready to show, or "".
    property string failure: ""

    readonly property bool enabled: Networking.wifiEnabled

    // Empty until the NetworkManager backend finishes connecting, about a
    // second after startup, so everything downstream has to be a binding.
    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property var active: (root.device?.networks?.values ?? []).find(n => n.connected) ?? null
    readonly property string activeName: root.active?.name ?? ""
    readonly property bool connected: root.enabled && root.active !== null

    // 0..1
    readonly property real strength: root.active?.signalStrength ?? 0

    // The wifi card itself: its interface and hardware (MAC) address.
    readonly property string interfaceName: root.device?.name ?? ""
    readonly property string hardwareAddress: root.device?.address ?? ""

    // Whether the connection reaches the internet, in words, or "" while
    // NetworkManager has not checked.
    readonly property string internet: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full:
            return "online";
        case NetworkConnectivity.Portal:
            return "sign-in page";
        case NetworkConnectivity.Limited:
            return "limited";
        case NetworkConnectivity.None:
            return "offline";
        }
        return "";
    }

    // The connected network first, then by bars, then by name. By bars rather
    // than raw strength, so the list only reorders when a network gains or
    // loses a bar, not with every flicker of signal: the row in use stays put.
    // A hidden network has no name to show, so it is left out. Worked out
    // only while something shows it.
    readonly property var networks: root.watchers === 0 ? [] : (root.device?.networks?.values ?? []).filter(n => n.name !== "").sort((a, b) => {
        if (a.connected !== b.connected)
            return a.connected ? -1 : 1;
        const bars = Icons.bars(b.signalStrength) - Icons.bars(a.signalStrength);
        if (bars !== 0)
            return bars;
        return a.name.localeCompare(b.name, undefined, {
            numeric: true
        });
    })

    function setEnabled(on: bool): void {
        Networking.wifiEnabled = on;
    }

    // Whether joining it needs a password. Enhanced open (OWE) is encrypted
    // but asks for nothing.
    function secured(network: var): bool {
        const security = network?.security ?? WifiSecurityType.Open;
        return security !== WifiSecurityType.Open && security !== WifiSecurityType.Owe;
    }

    function securityName(network: var): string {
        switch (network?.security) {
        case WifiSecurityType.Open:
            return "open";
        case WifiSecurityType.Owe:
            return "enhanced open";
        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep:
            return "wep";
        case WifiSecurityType.WpaPsk:
            return "wpa";
        case WifiSecurityType.Wpa2Psk:
            return "wpa2";
        case WifiSecurityType.Sae:
            return "wpa3";
        case WifiSecurityType.WpaEap:
            return "wpa enterprise";
        case WifiSecurityType.Wpa2Eap:
            return "wpa2 enterprise";
        case WifiSecurityType.Wpa3SuiteB192:
            return "wpa3 enterprise";
        case WifiSecurityType.Leap:
            return "leap";
        }
        return "";
    }

    function connecting(network: var): bool {
        return network?.state === ConnectionState.Connecting;
    }

    // The saved profile, which says settingsChanged when it changes, or null.
    function savedSettings(network: var): var {
        return network?.nmSettings?.[0] ?? null;
    }

    // What the saved profile says beyond the row, read once. It never holds
    // the password. autoconnect is left out of a profile while it is at its
    // default, which is on; lastUsed is in seconds since the epoch, or 0;
    // accessPoints counts those seen under the name, such as a router's two
    // bands or a router and its repeaters.
    function savedDetails(network: var): var {
        const profile = root.savedSettings(network)?.read() ?? {};
        return {
            autoJoin: profile.connection?.autoconnect ?? true,
            lastUsed: profile.connection?.timestamp ?? 0,
            accessPoints: profile["802-11-wireless"]?.["seen-bssids"]?.length ?? 0
        };
    }

    // write() updates only the fields it is given, so the rest of the
    // profile, the password included, is left as it was.
    function setAutoJoin(network: var, on: bool): void {
        root.savedSettings(network)?.write({
            connection: {
                autoconnect: on
            }
        });
    }

    function disconnect(network: var): void {
        network?.disconnect();
    }

    // Starts joining: straight away when NetworkManager already has what it
    // needs, else by asking for a password first.
    function join(network: var): void {
        if (!network || network.connected)
            return;
        root.cancel();
        root.joining = network;
        if (network.known || !root.secured(network)) {
            network.connect();
            return;
        }
        // A password is all this shell asks for: enterprise and WEP networks
        // need settings it has no form for.
        if (!root.passwordJoins(network)) {
            root.failure = "needs setting up in networkmanager";
            return;
        }
        root.needsPassword = true;
    }

    function submit(password: string): void {
        if (!root.joining || root.busy)
            return;
        // WPA passphrases are 8 to 63 characters: anything else is wrong
        // before NetworkManager is asked.
        if (root.wpaPassphrase(root.joining) && (password.length < 8 || password.length > 63)) {
            root.failure = "passwords are 8 to 63 characters";
            return;
        }
        root.failure = "";
        root.busy = true;
        attemptTimeout.restart();
        root.joining.connectWithPsk(password);
    }

    // Gives the attempt up. One abandoned after its password went out, before
    // NetworkManager answered, would leave a profile holding that password;
    // nothing here worked, so it is cleared.
    function cancel(): void {
        attemptTimeout.stop();
        if (root.busy && root.joining && !root.joining.connected)
            root.joining.forget();
        root.joining = null;
        root.needsPassword = false;
        root.busy = false;
        root.failure = "";
    }

    // Gives the attempt up unless its password is already out: that one is
    // left to finish, and a rejection still clears its profile.
    function abandon(): void {
        if (!root.busy)
            root.cancel();
    }

    function forget(network: var): void {
        if (network === root.joining)
            root.cancel();
        network?.forget();
    }

    // Ends a try NetworkManager answered or let hang: shows why, and clears
    // the profile a sent password left behind. NetworkManager saves it the
    // moment the password goes out, before it learns the password is wrong;
    // clearing it lets the retry write a fresh one.
    function settle(message: string, sent: bool): void {
        attemptTimeout.stop();
        root.busy = false;
        root.failure = message;
        root.needsPassword = root.passwordJoins(root.joining);
        if (sent)
            root.joining.forget();
    }

    function passwordJoins(network: var): bool {
        return root.wpaPassphrase(network) || network?.security === WifiSecurityType.Sae;
    }

    function wpaPassphrase(network: var): bool {
        return network?.security === WifiSecurityType.WpaPsk || network?.security === WifiSecurityType.Wpa2Psk;
    }

    function failureMessage(reason: int): string {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "wrong password";
        case ConnectionFailReason.WifiAuthTimeout:
            return "timed out signing in";
        case ConnectionFailReason.WifiNetworkLost:
            return "out of range";
        }
        return "couldn't connect";
    }

    function applyScanner(): void {
        if (root.device)
            root.device.scannerEnabled = root.watchers > 0 && root.enabled;
    }

    // Cycling the scanner is what asks NetworkManager for a fresh sweep.
    function rescan(): void {
        if (!root.device)
            return;
        root.device.scannerEnabled = false;
        root.device.scannerEnabled = true;
    }

    onWatchersChanged: root.applyScanner()
    onDeviceChanged: root.applyScanner()
    onEnabledChanged: {
        root.applyScanner();
        if (!root.enabled)
            root.cancel();
    }

    // NetworkManager completes a scan about every 14 seconds and drops
    // requests made sooner, so asking faster gains nothing.
    Timer {
        running: root.watchers > 0 && root.enabled
        interval: 15000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.rescan()
    }

    // NetworkManager can leave an attempt hanging.
    Timer {
        id: attemptTimeout

        interval: 20000
        onTriggered: root.settle("couldn't connect", true)
    }

    Connections {
        target: root.joining

        function onConnectionFailed(reason: int): void {
            const sent = root.busy;
            // Asking for a password nobody has typed yet is the prompt, not a
            // rejection, so it opens the prompt without an error.
            const asking = reason === ConnectionFailReason.NoSecrets && !sent;
            root.settle(asking ? "" : root.failureMessage(reason), sent);
        }

        function onConnectedChanged(): void {
            if (root.joining?.connected)
                root.cancel();
        }
    }
}
