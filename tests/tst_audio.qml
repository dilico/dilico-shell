import QtQuick
import QtTest
import qs.modules.island.components
import qs.services

Item {
    width: 400
    height: 700

    TestNode {
        id: speaker

        nickname: "Speaker"
        isSink: true
        where: "built-in"
        audio: ({
                volume: 0.59,
                muted: false
            })
    }

    TestNode {
        id: headphones

        nickname: "WH-1000XM4"
        isSink: true
        kind: "headphones"
        where: "bluetooth"
        audio: ({
                volume: 0.3,
                muted: true
            })
    }

    Component {
        id: cardComponent

        AudioCard {
            width: 360
            height: 306
        }
    }

    Component {
        id: sliderComponent

        SliderRow {
            y: 400
            width: 360
            label: "volume"
            detailLabel: "show outputs"
        }
    }

    Component {
        id: volumeLevelComponent

        VolumeLevel {}
    }

    ListCardCase {
        name: "AudioCard"
        service: Audio

        function init() {
            Audio.muted = false;
            Audio.listsReady = true;
            Audio.sink = speaker;
            Audio.outputs = [speaker, headphones];
            card = createTemporaryObject(cardComponent, parent);
            Audio.calls = [];
            waitForRendering(card);
        }

        function test_rows() {
            compare(findChild(row(speaker), "summary").text, "built-in · 59%");
            compare(findChild(row(headphones), "summary").text, "bluetooth · muted");
            verify(row(speaker).current, "the output in use");
            compare(row(speaker).statusText(), "in use");
            verify(!row(headphones).current);
        }

        function test_clickingAnOutputSelectsIt() {
            mouseClick(row(headphones), 60, 23);
            compare(lastCall(), ["select", "WH-1000XM4"]);
        }

        function test_switchIsSoundOn() {
            verify(switchControl().checked);
            mouseClick(switchControl());
            compare(lastCall(), ["toggleMuted", ""]);
            Audio.muted = true;
            verify(!switchControl().checked);
            verify(findChild(card, "list").visible, "muted still has outputs to choose between");
        }

        function test_showsNothingUntilComplete() {
            Audio.listsReady = false;
            verify(!findChild(card, "list").visible, "no rows that are about to go");
            Audio.listsReady = true;
            verify(findChild(card, "list").visible);
        }

        function test_noDetails() {
            verify(!findChild(row(speaker), "details").visible);
        }
    }

    TestCase {
        name: "SliderRow"
        when: windowShown

        function test_chevronIsSeparateFromMute() {
            const slider = createTemporaryObject(sliderComponent, parent);
            let toggles = 0;
            let details = 0;
            slider.toggled.connect(() => toggles++);
            slider.detailClicked.connect(() => details++);
            mouseClick(slider, slider.width - 10, slider.height / 2);
            compare(details, 1);
            compare(toggles, 0, "the chevron does not mute");
            mouseClick(slider, 10, slider.height / 2);
            compare(toggles, 1);
            compare(details, 1, "the mute button does not open the list");
        }
    }

    TestCase {
        name: "VolumeLevel"
        when: windowShown

        function test_widthHoldsWhileTheNumberGrows() {
            const level = createTemporaryObject(volumeLevelComponent, parent, { value: 0.05 });
            // A Row lays itself out on the next frame.
            waitForRendering(level);
            const narrow = level.implicitWidth;
            level.value = 1;
            waitForRendering(level);
            compare(level.implicitWidth, narrow, "the pill keeps its width from 5% to 100%");
        }
    }

    component TestNode: QtObject {
        property string nickname
        property bool isSink
        property string kind
        property string where
        property var audio
    }
}
