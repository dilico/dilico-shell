import QtQuick
import QtTest
import qs.modules.island.components
import qs.utils

Item {
    width: 400
    height: 340

    Component {
        id: cardComponent

        CalendarCard {
            today: new Date(2026, 9, 17, 19, 40)
        }
    }

    TestCase {
        name: "Calendar"

        function test_weeksStartOnTheFirstDay() {
            // 1 October 2026 is a Thursday.
            const monday = Calendar.weeks(new Date(2026, 9, 1), 1);
            compare(monday.length, 42);
            verify(Calendar.sameDay(monday[0], new Date(2026, 8, 28)), "the Monday before");
            verify(Calendar.sameDay(monday[3], new Date(2026, 9, 1)));
            verify(Calendar.sameDay(monday[41], new Date(2026, 10, 8)));
            const sunday = Calendar.weeks(new Date(2026, 9, 1), 0);
            verify(Calendar.sameDay(sunday[0], new Date(2026, 8, 27)), "the Sunday before");
        }

        function test_monthStartingTheDayBeforeTheFirstDay() {
            // 1 November 2026 is a Sunday: a whole week of October leads.
            verify(Calendar.sameDay(Calendar.weeks(new Date(2026, 10, 1), 1)[0], new Date(2026, 9, 26)));
        }

        function test_monthStartingOnTheFirstDayHasNoLead() {
            // 1 June 2026 is a Monday.
            verify(Calendar.sameDay(Calendar.weeks(new Date(2026, 5, 1), 1)[0], new Date(2026, 5, 1)));
        }

        function test_monthAcrossTheYear() {
            verify(Calendar.sameDay(Calendar.month(new Date(2026, 11, 31), 1), new Date(2027, 0, 1)));
            verify(Calendar.sameDay(Calendar.month(new Date(2026, 0, 15), -1), new Date(2025, 11, 1)));
        }

        function test_weekdays() {
            compare(Calendar.weekdays(1), [1, 2, 3, 4, 5, 6, 0]);
            compare(Calendar.weekdays(0), [0, 1, 2, 3, 4, 5, 6]);
        }
    }

    TestCase {
        name: "CalendarCard"
        when: windowShown

        property CalendarCard card

        function init() {
            card = createTemporaryObject(cardComponent, parent);
            waitForRendering(card);
        }

        function title(): string {
            return findChild(card, "title").text;
        }

        function test_opensOnThisMonth() {
            compare(title(), "october 2026");
            verify(!findChild(card, "thisMonth").visible, "already on it");
        }

        function test_marksToday() {
            const days = findChild(card, "days");
            const marked = [];
            for (let i = 0; i < days.count; i++) {
                if (days.itemAt(i).isToday)
                    marked.push(days.itemAt(i).modelData.getDate());
            }
            compare(marked, [17]);
        }

        function test_movesBetweenMonthsAndBack() {
            mouseClick(findChild(card, "next"));
            compare(title(), "november 2026");
            mouseClick(findChild(card, "next"));
            mouseClick(findChild(card, "next"));
            compare(title(), "january 2027");
            const today = findChild(card, "thisMonth");
            verify(today.visible);
            // The header row places the word on the next frame.
            waitForRendering(card);
            mouseClick(today);
            compare(title(), "october 2026");
            mouseClick(findChild(card, "previous"));
            compare(title(), "september 2026");
        }

        function test_followsTheClockOverMidnight() {
            card.today = new Date(2026, 10, 1, 0, 1);
            compare(title(), "november 2026");
        }
    }
}
