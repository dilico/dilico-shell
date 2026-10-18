import QtQuick
import QtTest
import qs.modules.island.panels
import qs.services
import qs.utils

Item {
    width: 600
    height: 600

    readonly property var apps: [
        { id: "firefox.desktop", name: "Firefox", genericName: "Web Browser", comment: "Browse the web", keywords: ["internet", "www"] },
        { id: "code.desktop", name: "Visual Studio Code", genericName: "Text Editor", comment: "Code editing", keywords: ["vscode"] },
        { id: "ghostty.desktop", name: "Ghostty", genericName: "Terminal", comment: "A terminal emulator", keywords: ["shell", "prompt"] },
        { id: "files.desktop", name: "Files", genericName: "File Manager", comment: "Access and organise files", keywords: ["folder", "explorer"] },
        { id: "gimp.desktop", name: "GNU Image Manipulation Program", genericName: "Image Editor", comment: "Create images", keywords: ["gimp"] }
    ]

    function names(list: var): var {
        return list.map(app => app.name);
    }

    TestCase {
        name: "Search"

        function test_nameStartBeatsAWordStartBeatsAnywhere() {
            verify(Search.score("fi", "Firefox", []) > Search.score("fi", "GNU Files", []));
            verify(Search.score("fi", "GNU Files", []) > Search.score("fi", "Profiler", []));
        }

        function test_otherWordsAndInitials() {
            compare(Search.score("terminal", "Ghostty", ["Terminal"]), 40);
            compare(Search.score("vsc", "Visual Studio Code", []), 10, "initials");
            compare(Search.score("fir", "Colour Profile Viewer", ["Inspect profiles"]), 0, "letters strewn about are no match");
        }

        function test_rank() {
            compare(names(Search.rankApps("fi", apps, {})), ["Files", "Firefox"], "two names that start with it, by name");
            compare(names(Search.rankApps("web", apps, {})), ["Firefox"], "a generic name");
            compare(names(Search.rankApps("c", apps, {})), ["Visual Studio Code", "GNU Image Manipulation Program"], "a word of the name, then a word of the comment");
            compare(names(Search.rankApps("  Ed ", apps, {})), ["Visual Studio Code", "GNU Image Manipulation Program"].sort(), "trimmed, case folded, ties by name");
        }

        function test_mostLaunchedFirstAmongEquals() {
            compare(names(Search.rankApps("f", apps, { "firefox.desktop": 2 })), ["Firefox", "Files"], "launches break a tie");
            compare(names(Search.rankApps("c", apps, { "gimp.desktop": 9 })), ["Visual Studio Code", "GNU Image Manipulation Program"], "but never beat a better match");
        }

        function test_nothingTypedIsByName() {
            compare(names(Search.rankApps("", apps, { "gimp.desktop": 3, "ghostty.desktop": 5 })), ["Files", "Firefox", "Ghostty", "GNU Image Manipulation Program", "Visual Studio Code"], "launches do not count");
        }
    }

    Component {
        id: launcherComponent

        Launcher {}
    }

    TestCase {
        name: "Launcher"
        when: windowShown

        property Launcher launcher

        function init() {
            Apps.all = apps;
            Apps.launches = {};
            Apps.calls = [];
            launcher = createTemporaryObject(launcherComponent, parent);
            waitForRendering(launcher);
        }

        function shown(): var {
            return names(launcher.matches);
        }

        function type(text: string): void {
            for (const c of text)
                keyClick(c);
        }

        function test_typesStraightIntoTheField() {
            type("gho");
            compare(findChild(launcher, "query").text, "gho");
            compare(shown(), ["Ghostty"]);
        }

        function test_enterLaunchesTheBest() {
            let launched = 0;
            launcher.launched.connect(() => launched++);
            type("term");
            keyClick(Qt.Key_Return);
            compare(Apps.calls, ["Ghostty"]);
            compare(launched, 1, "and the island closes");
        }

        function test_arrowsMoveThePick() {
            type("e");
            const first = shown();
            keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Up);
            compare(launcher.current, 1);
            keyClick(Qt.Key_Up);
            keyClick(Qt.Key_Up);
            compare(launcher.current, 0, "stops at the top");
            keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Return);
            compare(Apps.calls, [first[1]]);
        }

        function test_escapeBacksOut() {
            let cancelled = 0;
            launcher.cancelled.connect(() => cancelled++);
            type("x");
            keyClick(Qt.Key_Escape);
            compare(cancelled, 1);
            compare(Apps.calls, []);
        }

        function test_clickLaunches() {
            mouseClick(findChild(launcher, "matches").itemAtIndex(2));
            compare(Apps.calls, [shown()[2]]);
        }

        // Twenty apps: more than the eight a page shows.
        function many(): var {
            return Array.from({ length: 20 }, (_, i) => ({
                        id: `app${i}.desktop`,
                        name: `App ${String(i).padStart(2, "0")}`,
                        genericName: "",
                        comment: "",
                        keywords: []
                    }));
        }

        function test_everyMatchIsThere() {
            Apps.all = many();
            compare(shown().length, 20, "not just a page of them");
            compare(findChild(launcher, "matches").count, 20);
        }

        function test_arrowsScrollPastThePage() {
            Apps.all = many();
            const list = findChild(launcher, "matches");
            for (let i = 0; i < 12; i++)
                keyClick(Qt.Key_Down);
            compare(launcher.current, 12);
            waitForRendering(launcher);
            verify(list.contentY > 0, "scrolled down to it");
            const row = list.itemAtIndex(12);
            verify(row.y >= list.contentY && row.y + row.height <= list.contentY + list.height, "and it is in sight");
            keyClick(Qt.Key_Return);
            compare(Apps.calls, ["App 12"]);
        }

        function test_movingWithinThePageLeavesItBe() {
            Apps.all = many();
            keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Down);
            compare(findChild(launcher, "matches").contentY, 0);
        }

        function test_theWheelScrolls() {
            Apps.all = many();
            const list = findChild(launcher, "matches");
            waitForRendering(launcher);
            mouseWheel(list, list.width / 2, list.height / 2, 0, -360);
            tryVerify(() => list.contentY > 0, 1000, "the wheel scrolls the list");
            type("app");
            compare(list.contentY, 0, "and typing starts again from the top");
        }

        function test_typingAgainGoesBackToTheTop() {
            Apps.all = many();
            const list = findChild(launcher, "matches");
            for (let i = 0; i < 12; i++)
                keyClick(Qt.Key_Down);
            type("app");
            compare(launcher.current, 0);
            compare(list.contentY, 0);
        }

        function test_nothingMatches() {
            type("zzz");
            compare(shown(), []);
            keyClick(Qt.Key_Return);
            compare(Apps.calls, [], "Enter with nothing to launch does nothing");
        }

        function test_heightHoldsWhileTyping() {
            const tall = launcher.implicitHeight;
            type("zzz");
            compare(launcher.implicitHeight, tall, "the island does not resize under the typing");
        }
    }
}
