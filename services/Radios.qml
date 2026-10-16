pragma Singleton

import Quickshell
import qs.services

Singleton {
    id: root

    // Airplane mode is both radios off. It is read from them rather than stored,
    // so it stays true to whatever turned them off: this, a tile, or rfkill.
    readonly property bool airplane: !Network.enabled && !Bluez.enabled

    function setAirplane(on: bool): void {
        Network.setEnabled(!on);
        Bluez.setEnabled(!on);
    }
}
