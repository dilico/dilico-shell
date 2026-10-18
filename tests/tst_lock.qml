import QtQuick
import QtTest
import qs.modules.lock
import qs.services

Item {
    width: 1440
    height: 900

    Component {
        id: lockComponent

        LockScreen {
            anchors.fill: parent
            date: new Date(2026, 9, 18, 10, 24)
        }
    }

    TestCase {
        name: "LockScreen"
        when: windowShown

        property LockScreen lock

        function init() {
            Auth.busy = false;
            Auth.failure = "";
            Auth.calls = [];
            Battery.available = true;
            Keyboard.capsLock = false;
            Network.enabled = true;
            Network.connected = true;
            lock = createTemporaryObject(lockComponent, parent);
            waitForRendering(lock);
        }

        function password(): var {
            return findChild(lock, "password");
        }

        function notice(): var {
            return findChild(lock, "notice");
        }

        function type(text: string): void {
            for (const c of text)
                keyClick(c);
        }

        function test_clockAndDate() {
            compare(findChild(lock, "clock").text, "10:24");
            compare(findChild(lock, "date").text, "sun 18 oct 2026");
        }

        function test_typesStraightAway() {
            type("hunter2");
            compare(password().text, "hunter2", "the field has the keyboard without a click");
        }

        function test_enterChecksAndClears() {
            type("hunter2");
            keyClick(Qt.Key_Return);
            compare(Auth.calls, ["hunter2"]);
            compare(password().text, "", "a wrong one is typed again from nothing");
        }

        function test_escapeEmptiesTheField() {
            type("oops");
            keyClick(Qt.Key_Escape);
            compare(password().text, "");
            compare(Auth.calls, []);
        }

        function test_noticeFollowsTheCheck() {
            verify(!notice().visible, "nothing over the prompt at rest");
            Auth.busy = true;
            compare(notice().text, "checking");
            verify(notice().visible);
            verify(password().readOnly, "no typing while it checks");
            Auth.busy = false;
            Auth.failure = "wrong password";
            compare(notice().text, "wrong password");
            Auth.failure = "";
            verify(!notice().visible, "gone once a new check starts");
        }

        function test_capsLockStandsOut() {
            const caps = findChild(lock, "caps");
            compare(caps.text, "caps off");
            Keyboard.capsLock = true;
            compare(caps.text, "caps on");
            compare(caps.font.weight, Font.DemiBold);
        }

        function test_wifiInWords() {
            compare(lock.wifiText(), "wifi");
            Network.connected = false;
            compare(lock.wifiText(), "no wifi");
            Network.enabled = false;
            compare(lock.wifiText(), "wifi off");
        }

        function test_watchesTheKeyboard() {
            compare(Keyboard.watchers, 1, "caps lock is read while the lock shows");
        }
    }
}
