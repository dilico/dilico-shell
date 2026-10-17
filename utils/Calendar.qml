pragma Singleton

import QtQuick
import Quickshell

// A month laid out in weeks. Each function answers from its arguments alone.
// Weekdays are numbered as Qt's Locale numbers them: 0 is Sunday.
Singleton {
    id: root

    // The first of the month `offset` months from the one d is in.
    function month(d: date, offset: int): date {
        return new Date(d.getFullYear(), d.getMonth() + offset, 1);
    }

    // The six weeks that hold a month, from the week starting on firstDay:
    // 42 dates, the month's own and the days either side that fill its
    // first and last weeks.
    function weeks(first: date, firstDay: int): var {
        const lead = (first.getDay() - firstDay + 7) % 7;
        return Array.from({ length: 42 }, (_, i) => new Date(first.getFullYear(), first.getMonth(), 1 - lead + i));
    }

    // The days of the week from firstDay, as numbers.
    function weekdays(firstDay: int): var {
        return Array.from({ length: 7 }, (_, i) => (firstDay + i) % 7);
    }

    function sameDay(a: date, b: date): bool {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }
}
