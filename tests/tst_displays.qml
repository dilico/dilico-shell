import QtQuick
import QtTest
import qs.modules.island.components
import qs.services
import qs.utils

Item {
    width: 400
    height: 340

    Component {
        id: cardComponent

        DisplaysCard {
            width: 360
            height: 306
        }
    }

    function rect(name: string, x: int, y: int, width: int, height: int): var {
        return {
            name,
            x,
            y,
            width,
            height
        };
    }

    function byName(rects: var, name: string): var {
        return rects.find(r => r.name === name);
    }

    TestCase {
        name: "Arrange"

        function test_sizeIsTheModeOverTheScaleTurnedWithTheMonitor() {
            compare(Arrange.size(2560, 1440, 1, 0), { width: 2560, height: 1440 });
            compare(Arrange.size(2560, 1440, 1.25, 0), { width: 2048, height: 1152 });
            compare(Arrange.size(2560, 1440, 1, 1), { width: 1440, height: 2560 }, "on its side");
            compare(Arrange.size(2560, 1440, 1, 2), { width: 2560, height: 1440 }, "upside down");
        }

        function test_droppedNearASideTouchesIt() {
            const rects = [rect("big", 0, 0, 2560, 1440), rect("small", 0, 1440, 1920, 1200)];
            const right = Arrange.place(rects, "small", 2700, 600);
            compare(byName(right, "small").x, 2560, "flush with the right edge");
            compare(byName(right, "small").y, 600, "where it was dropped along it");
            const above = Arrange.place(rects, "small", -1000, -1500);
            compare(byName(above, "small"), rect("small", 0, 0, 1920, 1200), "the layout starts at 0 again");
            compare(byName(above, "big"), rect("big", 1000, 1200, 2560, 1440));
        }

        function test_linesUpWithTheEdgesAndTheMiddle() {
            const rects = [rect("big", 0, 0, 2560, 1440), rect("small", 0, 1440, 1920, 1200)];
            compare(byName(Arrange.place(rects, "small", 2600, 30), "small").y, 0, "tops line up");
            compare(byName(Arrange.place(rects, "small", 2600, 200), "small").y, 240, "middles line up");
            compare(byName(Arrange.place(rects, "small", 350, 1500), "small").x, 320, "below, centred");
            compare(byName(Arrange.place(rects, "small", 680, 1500), "small").x, 640, "below, right sides lined up");
        }

        function test_keepsTouching() {
            const rects = [rect("big", 0, 0, 2560, 1440), rect("small", 0, 1440, 1920, 1200)];
            // Against the right side, sharing a tenth of the shorter one's.
            compare(byName(Arrange.place(rects, "small", 9000, 9000), "small"), rect("small", 2560, 1320, 1920, 1200));
        }

        function test_neverCoversAnother() {
            const rects = [rect("a", 0, 0, 1000, 1000), rect("b", 1000, 0, 1000, 1000), rect("c", 0, 1000, 1000, 1000)];
            // Dropped where a's right side meets b.
            const placed = Arrange.place(rects, "c", 1000, 300);
            for (const other of placed.filter(r => r.name !== "c"))
                verify(!Arrange.overlap(byName(placed, "c"), other), `clear of ${other.name}`);
        }

        function test_rectsAndPlacedGoBetweenMonitorsAndTheLayout() {
            const monitors = [{ name: "a", width: 2560, height: 1440, scale: 2, transform: 1, x: 5, y: 6, model: "kept" }];
            compare(Arrange.rects(monitors), [rect("a", 5, 6, 720, 1280)]);
            compare(Arrange.placed(monitors, [rect("a", 0, 0, 720, 1280)])[0], Object.assign({}, monitors[0], { x: 0, y: 0 }));
        }

        function test_aloneAtTheOrigin() {
            compare(byName(Arrange.place([rect("only", 300, 200, 1920, 1200)], "only", 50, 50), "only"), rect("only", 0, 0, 1920, 1200));
        }

        function test_settleClosesTheGapAShrinkLeaves() {
            // The big one, above, has gone from 1440 rows to 1080.
            const settled = Arrange.settle([rect("big", 0, 0, 1920, 1080), rect("small", 0, 1440, 1920, 1200)], "big");
            compare(byName(settled, "small").y, 1080);
        }

        function test_settleMovesOneTheGrowthCovers() {
            const settled = Arrange.settle([rect("big", 0, 0, 3840, 2160), rect("small", 0, 1440, 1920, 1200)], "big");
            verify(!Arrange.overlap(byName(settled, "big"), byName(settled, "small")));
            compare(byName(settled, "small").y, 2160);
        }

        function test_fitCentresTheLayoutInTheBox() {
            const fit = Arrange.fit([rect("big", 0, 0, 2000, 1000)], 400, 200, 0);
            compare(fit.scale, 0.2);
            compare(fit.x, 0);
            compare(fit.y, 0);
            const tall = Arrange.fit([rect("big", 0, 0, 1000, 1000)], 400, 200, 0);
            compare(tall.x, 100, "centred across");
        }
    }

    TestCase {
        name: "MonitorRules"

        readonly property var rule: ({
                output: "desc:BOE 0x0B9C",
                mode: "1920x1200@60.00",
                x: 0,
                y: 1440,
                scale: "1",
                transform: 0
            })

        function test_callIsHyprlandsMonitorRule() {
            compare(MonitorRules.call(rule), 'hl.monitor({ output = "desc:BOE 0x0B9C", mode = "1920x1200@60.00", position = "0x1440", scale = "1", transform = 0 })');
        }

        function test_aFileReadsBackAsItsRules() {
            const odd = Object.assign({}, rule, {
                output: 'desc:Acme "Pro" \\ 27',
                x: -1920,
                scale: "1.25",
                transform: 1
            });
            compare(MonitorRules.parse(MonitorRules.file([rule, odd])), [rule, odd]);
        }

        function test_linesInAnyOtherFormAreLeftOut() {
            const text = `${MonitorRules.call(rule)}\nhl.monitor({ output = "DP-1", mode = "preferred" })\n-- a comment\n`;
            compare(MonitorRules.parse(text), [rule]);
        }

        function test_mergeKeepsMonitorsNotPluggedIn() {
            const away = Object.assign({}, rule, { output: "desc:Away 24" });
            const byPort = Object.assign({}, rule, { output: "eDP-1" });
            const now = Object.assign({}, rule, {
                port: "eDP-1",
                y: 0
            });
            compare(MonitorRules.merge([away, byPort], [now]), [away, now], "the one named by port is replaced");
            compare(MonitorRules.merge([rule, away], [now]), [away, now], "and the one named by description");
        }

        function test_modeAsHyprctlListsIt() {
            compare(MonitorRules.mode("2560x1440@143.97Hz"), { width: 2560, height: 1440, refresh: 143.97 });
            compare(MonitorRules.mode("preferred"), null);
            compare(MonitorRules.modeText(2560, 1440, 143.973), "2560x1440@143.97");
        }

        function test_aMonitorsRuleNamesItByDescription() {
            const laptop = {
                name: "eDP-1",
                description: "BOE 0x0B9C",
                width: 1920,
                height: 1200,
                refresh: 60.003,
                x: 0,
                y: 1440,
                scale: 1.25,
                transform: 0
            };
            compare(MonitorRules.rule(laptop), {
                output: "desc:BOE 0x0B9C",
                port: "eDP-1",
                mode: "1920x1200@60.00",
                x: 0,
                y: 1440,
                scale: "1.25",
                transform: 0
            });
            compare(MonitorRules.rule(Object.assign({}, laptop, { description: "" })).output, "eDP-1", "or by port, without one");
        }

        function test_sameModeAllowsForTheMeasuredRate() {
            const m = { width: 2560, height: 1440, refresh: 143.998 };
            verify(MonitorRules.sameMode({ width: 2560, height: 1440, refresh: 144 }, m));
            verify(!MonitorRules.sameMode({ width: 2560, height: 1440, refresh: 120 }, m));
            verify(!MonitorRules.sameMode({ width: 1920, height: 1080, refresh: 144 }, m));
        }
    }

    TestCase {
        name: "DisplaysCard"
        when: windowShown

        property DisplaysCard card

        function monitor(name: string, model: string, x: int, y: int, width: int, height: int, modes: var): var {
            return {
                name,
                builtIn: name === "eDP-1",
                model,
                description: `${model} desc`,
                width,
                height,
                refresh: 60.003,
                x,
                y,
                scale: 1,
                transform: 0,
                modes
            };
        }

        function init() {
            Displays.monitors = [
                monitor("DP-3", "U2720Q", 0, 0, 2560, 1440, [
                    { width: 2560, height: 1440, refresh: 144 },
                    { width: 2560, height: 1440, refresh: 60 },
                    { width: 1920, height: 1080, refresh: 60 }
                ]),
                monitor("eDP-1", "0x0B9C", 0, 1440, 1920, 1200, [{ width: 1920, height: 1200, refresh: 60 }])
            ];
            Displays.pending = false;
            Displays.calls = [];
            card = createTemporaryObject(cardComponent, parent);
            waitForRendering(card);
        }

        function tile(i: int): var {
            return findChild(card, "tiles").itemAt(i);
        }

        function modeRow(i: int): var {
            const list = findChild(card, "modes");
            list.positionViewAtIndex(i, ListView.Contain);
            return list.itemAtIndex(i);
        }

        function test_aTilePerMonitorWhereItSits() {
            const map = findChild(card, "map");
            const big = tile(0);
            const small = tile(1);
            verify(big.width > small.width, "drawn to scale");
            compare(small.y, big.y + big.height, "below it, as on the layout");
            for (const t of [big, small])
                verify(t.x >= 0 && t.y >= 0 && t.x + t.width <= map.width && t.y + t.height <= map.height, "inside the map");
        }

        function test_theFirstIsPickedAndItsModesListed() {
            verify(tile(0).picked);
            compare(findChild(card, "modes").count, 3);
            verify(!modeRow(0).active, "144 hz is not the mode in use");
            verify(modeRow(1).active, "60 hz is");
        }

        function test_tappingATilePicksIt() {
            mouseClick(findChild(tile(1), "pick"));
            verify(tile(1).picked);
            verify(!tile(0).picked);
            compare(findChild(card, "modes").count, 1);
        }

        function test_aModeClickedIsSet() {
            mouseClick(findChild(modeRow(2), "pick"));
            compare(Displays.calls, [["setMode", "DP-3", { width: 1920, height: 1080, refresh: 60 }]]);
        }

        function test_draggingATileMovesItsMonitor() {
            const small = tile(1);
            const map = findChild(card, "map");
            const scale = map.fit.scale;
            // On the map, which holds still while the tile moves.
            const from = Qt.point(small.x + small.width / 2, small.y + small.height / 2);
            mousePress(map, from.x, from.y);
            // Over in steps, so the drag passes its threshold first.
            for (let step = 1; step <= 10; step++)
                mouseMove(map, from.x + step * 8, from.y - step * 2, -1, Qt.LeftButton);
            mouseRelease(map, from.x + 80, from.y - 20);
            compare(Displays.calls.length, 1);
            const [what, name, x, y] = Displays.calls[0];
            compare(what, "move");
            compare(name, "eDP-1");
            fuzzyCompare(x, 80 / scale, 2 / scale, "by the distance dragged, on the layout");
            fuzzyCompare(y, 1440 - 20 / scale, 2 / scale);
            compare(small.moved, Qt.point(0, 0), "and back to where the layout puts it");
            verify(small.picked, "the one dragged is picked");
        }

        function test_aLoneMonitorStaysPut() {
            Displays.monitors = [Displays.monitors[1]];
            waitForRendering(card);
            const map = findChild(card, "map");
            const only = tile(0);
            const from = Qt.point(only.x + 10, only.y + 10);
            mousePress(map, from.x, from.y);
            for (let step = 1; step <= 10; step++)
                mouseMove(map, from.x + step * 8, from.y, -1, Qt.LeftButton);
            mouseRelease(map, from.x + 80, from.y);
            compare(Displays.calls, []);
        }

        function test_aTrialOffersToKeepOrUndo() {
            verify(!findChild(card, "keep").visible);
            Displays.secondsLeft = 12;
            Displays.pending = true;
            compare(findChild(card, "title").text, "keep this mode?");
            verify(findChild(card, "undo").visible);
            compare(findChild(card, "undo").text, "undo 12");
            waitForRendering(card);
            mouseClick(findChild(card, "keep"));
            mouseClick(findChild(card, "undo"));
            compare(Displays.calls, [["keep"], ["revert"]]);
        }

        function test_watchesWhileShown() {
            compare(Displays.watchers, 1);
            card.destroy();
            wait(0);
            compare(Displays.watchers, 0);
        }
    }
}
