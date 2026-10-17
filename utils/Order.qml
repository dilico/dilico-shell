pragma Singleton

import Quickshell

// Pieces of sort comparators, chained with ||: each says how two items
// compare on one thing, or 0 to leave it to the next.
Singleton {
    id: root

    // The one that is true goes first.
    function first(a: bool, b: bool): int {
        return a === b ? 0 : a ? -1 : 1;
    }

    // Alphabetical, with numbers in order: "HDMI 2" before "HDMI 10".
    function byName(a: string, b: string): int {
        return a.localeCompare(b, undefined, {
            numeric: true
        });
    }
}
