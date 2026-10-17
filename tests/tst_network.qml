import QtQuick
import QtTest
import qs.modules.island.components
import qs.services

Item {
    width: 400
    height: 700

    TestNetwork {
        id: studio

        name: "studio-5g"
        signalStrength: 0.8
    }

    TestNetwork {
        id: home

        name: "home"
        signalStrength: 0.4
        known: true
    }

    TestNetwork {
        id: chapel

        name: "the-chapel"
        signalStrength: 0.6
        known: true
        connected: true
    }

    TestNetwork {
        id: passing

        name: "passing-train"
        signalStrength: 0.3
        known: true
    }

    Component {
        id: rowComponent

        NetworkRow {
            y: 500
            width: 360
        }
    }

    Component {
        id: cardComponent

        NetworkCard {
            width: 360
            height: 420
        }
    }

    TestCase {
        name: "NetworkRow"
        when: windowShown

        function makeRow(network) {
            return createTemporaryObject(rowComponent, parent, {
                network
            });
        }

        function test_secondLine() {
            compare(findChild(makeRow(studio), "summary").text, "wpa2 · 80%");
            compare(findChild(makeRow(home), "summary").text, "wpa2 · 40% · saved");
            compare(findChild(makeRow(chapel), "summary").text, "wpa2 · 60%", "connected says so on the right instead");
        }

        function test_chevronOnlyForSaved() {
            verify(!findChild(makeRow(studio), "details").visible);
            const row = makeRow(home);
            let toggled = 0;
            row.detailsToggled.connect(() => toggled++);
            mouseClick(findChild(row, "details"));
            compare(toggled, 1);
        }

        // NetworkManager drops a network's object when it goes out of range,
        // which leaves its row holding null until the list catches up.
        function test_vanishedNetworkIsQuiet() {
            failOnWarning(/TypeError/);
            const row = makeRow(passing);
            row.detailsOpen = true;
            verify(row.visible);
            row.network = null;
            verify(!row.visible, "a row with no network is hidden");
            mouseClick(row, 60, 23);
        }
    }

    TestCase {
        name: "NetworkCard"
        when: windowShown

        property var card: null

        function row(network) {
            return findChild(card, "networks").itemAtIndex(Network.networks.indexOf(network));
        }

        function lastCall() {
            return Network.calls[Network.calls.length - 1];
        }

        // Opening a row changes its height; the list moves the rows under it
        // on its next layout pass, so a click has to wait for that.
        function clickWhenLaidOut(item) {
            waitForRendering(card);
            mouseClick(item);
        }

        function init() {
            Network.cancel();
            Network.networks = [chapel, studio, home];
            card = createTemporaryObject(cardComponent, parent);
            Network.calls = [];
            waitForRendering(card);
        }

        function test_securedOpensPromptAndSubmits() {
            mouseClick(row(studio), 60, 23);
            compare(lastCall(), ["join", "studio-5g"]);
            verify(row(studio).expanded);
            verify(row(studio).height > 46, "the prompt opens under the row");
            keyClick(Qt.Key_A);
            keyClick(Qt.Key_B);
            keyClick(Qt.Key_Return);
            compare(lastCall(), ["submit", "ab"]);
        }

        function test_escapeClosesPromptOnly() {
            mouseClick(row(studio), 60, 23);
            keyClick(Qt.Key_Escape);
            compare(lastCall(), ["cancel", ""]);
            verify(!row(studio).expanded);
            compare(row(studio).height, 46);
        }

        function test_clickingAnOpenPromptClosesIt() {
            mouseClick(row(studio), 60, 23);
            mouseClick(row(studio), 60, 23);
            compare(lastCall(), ["cancel", ""]);
        }

        function test_savedRowBodyJoins() {
            mouseClick(row(home), 60, 23);
            compare(lastCall(), ["join", "home"]);
            verify(!row(home).detailsOpen);
        }

        function test_savedChevronOpensDetailsAndForgets() {
            mouseClick(findChild(row(home), "details"));
            verify(row(home).detailsOpen);
            compare(Network.calls.length, 0, "the chevron does not join");
            verify(!findChild(row(home), "disconnect").visible, "only the connected network disconnects");
            clickWhenLaidOut(findChild(row(home), "forget"));
            compare(lastCall(), ["forget", "home"]);
        }

        function test_currentRowOpensDetailsOnClick() {
            mouseClick(row(chapel), 60, 23);
            verify(row(chapel).detailsOpen);
            compare(Network.calls.length, 0, "nothing to join");
            clickWhenLaidOut(findChild(row(chapel), "disconnect"));
            compare(lastCall(), ["disconnect", "the-chapel"]);
            clickWhenLaidOut(findChild(row(chapel), "autoJoin"));
            compare(lastCall(), ["setAutoJoin", false], "auto-join starts on and turns off");
        }

        function test_joiningCollapsesOpenDetails() {
            mouseClick(findChild(row(home), "details"));
            mouseClick(row(studio), 60, 23);
            verify(!row(home).detailsOpen, "the other row's details close");
            verify(row(studio).expanded, "and this row's prompt opens");
        }

        function test_detailsCollapseOpenPrompt() {
            mouseClick(row(studio), 60, 23);
            mouseClick(findChild(row(home), "details"));
            verify(!row(studio).expanded, "the other row's prompt closes");
            verify(row(home).detailsOpen);
        }

        function test_sentPasswordIsLeftToFinish() {
            mouseClick(row(studio), 60, 23);
            Network.busy = true;
            Network.calls = [];
            mouseClick(findChild(row(home), "details"));
            compare(Network.calls.length, 0, "no cancel while NetworkManager checks the password");
            card.destroy();
            wait(0);
            compare(Network.calls.length, 0, "nor when the list closes");
        }

        function test_closingGivesUpAnUnsentPrompt() {
            mouseClick(row(studio), 60, 23);
            card.destroy();
            wait(0);
            compare(lastCall(), ["cancel", ""]);
        }
    }

    component TestNetwork: QtObject {
        property string name
        property real signalStrength
        property bool connected
        property bool known
        property bool secured: true
        property bool connecting
    }
}
