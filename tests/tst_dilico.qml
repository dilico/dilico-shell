import QtQuick
import QtTest
import qs.components
import qs.config
import qs.utils

Item {
    width: 400
    height: 200

    Slider {
        id: slider

        property real last: -1

        width: 200
        height: 28
        value: 0.5
        onMoved: v => slider.last = v
    }

    Pressable {
        id: pressable

        property int clicks: 0

        y: 50
        width: 40
        height: 40
        onClicked: pressable.clicks++
    }

    Track {
        id: track

        y: 100
        width: 100
        height: 4
        inset: 8
        value: 0.5
    }

    QtObject {
        id: polled

        property int watchers: 0
    }

    Component {
        id: watchComponent

        Watch {}
    }

    TestCase {
        name: "Dilico"
        when: windowShown

        function init() {
            slider.last = -1;
            pressable.clicks = 0;
            pressable.interactive = true;
        }

        // The wheel moves the slider one step per notch of travel, however
        // the travel arrives.

        function test_wheel_oneNotch() {
            mouseWheel(slider, 100, 14, 0, -120);
            fuzzyCompare(slider.last, 0.45, 1e-9);
        }

        function test_wheel_sidewaysIgnored() {
            mouseWheel(slider, 100, 14, 120, 0);
            compare(slider.last, -1);
        }

        function test_wheel_touchpadAccumulates() {
            for (let i = 0; i < 7; i++)
                mouseWheel(slider, 100, 14, 0, 15);
            compare(slider.last, -1, "no step before a full notch of travel");
            mouseWheel(slider, 100, 14, 0, 15);
            fuzzyCompare(slider.last, 0.55, 1e-9);
        }

        function test_wheel_fastWheelTwoNotches() {
            mouseWheel(slider, 100, 14, 0, 240);
            fuzzyCompare(slider.last, 0.6, 1e-9);
        }

        function test_slider_accessibleSteps() {
            slider.Accessible.increaseAction();
            fuzzyCompare(slider.last, 0.55, 1e-9);
            slider.Accessible.decreaseAction();
            fuzzyCompare(slider.last, 0.45, 1e-9);
        }

        function test_track_fillStopsAtInset() {
            // 8 in from the left, then half of the 84 between the insets.
            compare(track.children[0].width, 50);
        }

        function test_watch_counts() {
            const a = watchComponent.createObject(null, { service: polled });
            const b = watchComponent.createObject(null, { service: polled });
            compare(polled.watchers, 2);
            a.destroy();
            wait(0);
            compare(polled.watchers, 1, "one closing leaves the other polling");
            b.destroy();
            wait(0);
            compare(polled.watchers, 0);
        }

        function test_pressable_clicks() {
            mouseClick(pressable);
            compare(pressable.clicks, 1);
            pressable.Accessible.pressAction();
            compare(pressable.clicks, 2, "a screen reader's press clicks too");
            pressable.interactive = false;
            mouseClick(pressable);
            pressable.Accessible.pressAction();
            compare(pressable.clicks, 2, "inert when not interactive");
        }

        function test_format() {
            compare(Format.percent(0.427), "43%");
            compare(Format.playTime(187), "3:07");
            compare(Format.playTime(-3), "0:00");
            compare(Format.duration(45 * 60), "45m");
            compare(Format.duration(65 * 60), "1h05m");
            compare(Format.time(new Date(2026, 9, 16, 9, 41)), "09:41");
            compare(Format.date(new Date(2026, 9, 16), "ddd dd MMMM"), "fri 16 october");
        }

        function test_icons() {
            compare(Icons.wifi(false, 1), Glyphs.wifiOff);
            compare(Icons.wifi(true, 0.8), Glyphs.wifi4);
            compare(Icons.wifi(true, 0.1), Glyphs.wifi1);
            compare(Icons.bluetooth(false, 2), Glyphs.bluetoothOff);
            compare(Icons.bluetooth(true, 2), Glyphs.bluetoothConnected);
            compare(Icons.volume(false, 0.2), Glyphs.volumeLow);
            compare(Icons.volume(true, 0.9), Glyphs.volumeOff);
        }
    }
}
