import QtQuick
import QtTest
import qs.modules.island.components
import qs.services

Item {
    width: 400
    height: 340

    Component {
        id: cardComponent

        ProcessCard {}
    }

    TestCase {
        name: "ProcessCard"
        when: windowShown

        property ProcessCard card

        function init() {
            Processes.ready = true;
            Processes.processes = Array.from({ length: 30 }, (_, i) => ({
                        pid: i + 1,
                        name: `proc${i + 1}`,
                        cpu: i / 100,
                        memory: (30 - i) * 1048576
                    }));
            Processes.calls = [];
            card = createTemporaryObject(cardComponent, parent);
            waitForRendering(card);
        }

        function row(i: int): var {
            return findChild(card, "rows").itemAt(i);
        }

        // A row's words show on the next frame, once its Row lays them out.
        function clickWhenLaidOut(item: var): void {
            waitForRendering(card);
            mouseClick(item);
        }

        function names(): var {
            const rows = findChild(card, "rows");
            return Array.from({ length: rows.count }, (_, i) => rows.itemAt(i).modelData.name);
        }

        function test_heaviestFirstBySortedColumn() {
            compare(names()[0], "proc30", "busiest cpu first");
            card.sortBy = "memory";
            compare(names()[0], "proc1", "largest memory first");
        }

        function test_asManyAsFit() {
            const shown = names().length;
            verify(shown > 0 && shown < 30, `shows ${shown}, which fit without scrolling`);
            verify(findChild(card, "rows").itemAt(shown - 1).y + card.rowHeight <= card.height);
        }

        function test_headingsReportTheSort() {
            const picked = [];
            card.sortPicked.connect(by => picked.push(by));
            mouseClick(findChild(card, "memory"));
            mouseClick(findChild(card, "cpu"));
            compare(picked, ["memory", "cpu"]);
            compare(card.sortBy, "cpu", "the owner decides");
        }

        function test_watchesWhileShown() {
            compare(Processes.watchers, 1);
            card.destroy();
            wait(0);
            compare(Processes.watchers, 0);
        }

        function test_clickOffersToEnd() {
            mouseClick(findChild(row(0), "pick"));
            verify(row(0).offered);
            verify(findChild(row(0), "end").visible);
            verify(!findChild(row(1), "end").visible, "one at a time");
            clickWhenLaidOut(findChild(row(0), "end"));
            compare(Processes.calls, [["end", 30]]);
            verify(!row(0).offered, "the offer is spent");
        }

        function test_killForces() {
            mouseClick(findChild(row(2), "pick"));
            clickWhenLaidOut(findChild(row(2), "kill"));
            compare(Processes.calls, [["kill", 28]]);
        }

        function test_holdsStillWhileOffered() {
            mouseClick(findChild(row(1), "pick"));
            const before = names();
            Processes.processes = Processes.processes.map(p => Object.assign({}, p, { cpu: 1 - p.cpu }));
            compare(names(), before, "no row moves under the pointer");
            compare(row(0).modelData.cpu, 1 - 0.29, "but the figures stay live");
            mouseClick(findChild(row(1), "pick"), 10, 10);
            verify(!row(1).offered, "clicking it again takes the offer back");
            compare(Processes.calls, []);
            verify(names()[0] !== before[0], "and the order moves again");
        }

        function test_rowsStayPutBetweenSamples() {
            const first = row(0);
            // Every sample is new objects, as the service makes them.
            Processes.processes = Processes.processes.map(p => Object.assign({}, p, { memory: p.memory * 2 }));
            verify(row(0) === first, "updated in place, so a hover survives");
            compare(row(0).modelData.memory, 2 * 1048576, "with the new figures");
        }

        function test_aProcessThatExitsDropsOut() {
            failOnWarning(/Binding loop/);
            mouseClick(findChild(row(0), "pick"));
            Processes.processes = Processes.processes.filter(p => p.pid !== 29);
            verify(!names().includes("proc29"), "gone from the held order");
            verify(row(0).offered, "the offer stays on the one picked");
            Processes.processes = Processes.processes.filter(p => p.pid !== 30);
            verify(!names().includes("proc30"));
            verify(!card.holding, "nothing left to offer");
        }

        function test_sortingTakesTheOfferBack() {
            mouseClick(findChild(row(0), "pick"));
            card.sortBy = "memory";
            verify(!row(0).offered);
            compare(names()[0], "proc1");
        }

        function test_nothingUntilMeasured() {
            Processes.ready = false;
            compare(names().length, 0);
        }
    }
}
