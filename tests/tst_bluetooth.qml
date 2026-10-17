import QtQuick
import QtTest
import qs.modules.island.components
import qs.services

Item {
    width: 400
    height: 700

    TestDevice {
        id: headphones

        name: "studio headphones"
        kind: "headphones"
        connected: true
        paired: true
        trusted: true
        batteryAvailable: true
        battery: 0.84
        address: "00:11:22:33:44:55"
    }

    TestDevice {
        id: keyboard

        name: "keychron k3"
        kind: "keyboard"
        paired: true
    }

    TestDevice {
        id: speaker

        name: "livingroom speaker"
        kind: "speaker"
    }

    Component {
        id: cardComponent

        BluetoothCard {
            width: 360
            height: 420
        }
    }

    ListCardCase {
        name: "BluetoothCard"
        service: Bluez

        function init() {
            speaker.activity = "";
            Bluez.devices = [headphones, keyboard, speaker];
            card = createTemporaryObject(cardComponent, parent);
            Bluez.calls = [];
            waitForRendering(card);
        }

        function test_secondLine() {
            compare(findChild(row(headphones), "summary").text, "headphones · 84%");
            compare(findChild(row(keyboard), "summary").text, "keyboard · paired");
            compare(findChild(row(speaker), "summary").text, "speaker");
        }

        function test_clickingADeviceConnectsIt() {
            mouseClick(row(keyboard), 60, 23);
            compare(lastCall(), ["connect", "keychron k3"]);
            mouseClick(row(speaker), 60, 23);
            compare(lastCall(), ["connect", "livingroom speaker"], "an unpaired one pairs, then connects");
        }

        function test_busyRowSaysWhatAndStops() {
            speaker.activity = "pairing";
            verify(row(speaker).busy);
            compare(row(speaker).busyText, "pairing");
            mouseClick(row(speaker), 60, 23);
            compare(lastCall(), ["stop", "livingroom speaker"]);
        }

        function test_connectedOpensDetails() {
            mouseClick(row(headphones), 60, 23);
            verify(row(headphones).detailsOpen);
            compare(Bluez.calls.length, 0, "nothing to connect");
            clickWhenLaidOut(findChild(row(headphones), "detailSwitch"));
            compare(lastCall(), ["setTrusted", false], "trusted, so it turns off");
            clickWhenLaidOut(findChild(row(headphones), "disconnect"));
            compare(lastCall(), ["disconnect", "studio headphones"]);
        }

        function test_pairedChevronOpensDetailsAndForgets() {
            mouseClick(findChild(row(keyboard), "details"));
            verify(row(keyboard).detailsOpen);
            verify(!findChild(row(keyboard), "disconnect").visible);
            clickWhenLaidOut(findChild(row(keyboard), "forget"));
            compare(lastCall(), ["forget", "keychron k3"]);
        }

        function test_unpairedHasNoDetails() {
            verify(!findChild(row(speaker), "details").visible);
        }

        function test_clickingAnotherCollapsesDetails() {
            mouseClick(findChild(row(keyboard), "details"));
            mouseClick(row(speaker), 60, 23);
            verify(!row(keyboard).detailsOpen);
        }

        function test_vanishedDeviceIsQuiet() {
            failOnWarning(/TypeError/);
            const r = row(keyboard);
            r.detailsOpen = true;
            r.device = null;
            verify(!r.visible);
        }
    }

    component TestDevice: QtObject {
        property string name
        property string kind
        property bool connected
        property bool paired
        property bool trusted
        property string activity
        property bool batteryAvailable
        property real battery
        property string address
    }
}
