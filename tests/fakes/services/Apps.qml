pragma Singleton

import QtQuick
import Quickshell
import qs.utils

// Stands in for services/Apps in tests: the same interface as far as the
// launcher uses it, ranking with the real Search.rankApps and recording launches
// instead of starting anything. A test app is { id, name, genericName,
// comment, keywords }.
Singleton {
    id: root

    property var all: []
    property var launches: ({})
    // Each app launched, by name; reset by tests.
    property var calls: []

    function search(query: string): var {
        return Search.rankApps(query, root.all, root.launches);
    }

    function icon(app: var): string {
        return "";
    }

    function launch(app: var): void {
        root.calls.push(app.name);
    }
}
