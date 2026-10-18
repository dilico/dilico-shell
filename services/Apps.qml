pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// The applications installed, as their desktop entries describe them, and how
// often each has been launched from here.
Singleton {
    id: root

    // Every entry that asks to be shown.
    readonly property var all: DesktopEntries.applications.values.filter(app => !app.noDisplay)

    // Launches so far, by desktop entry id. Kept across restarts.
    property var launches: ({})

    // Every app by name, or those that match the query, best first (see
    // Search.rankApps).
    function search(query: string): var {
        return Search.rankApps(query, root.all, root.launches);
    }

    // The entry's icon from the icon theme, or a generic one.
    function icon(app: var): string {
        return Quickshell.iconPath(app?.icon ?? "", "application-x-executable");
    }

    function launch(app: var): void {
        app.execute();
        root.launches = Object.assign({}, root.launches, {
            [app.id]: (root.launches[app.id] ?? 0) + 1
        });
        store.setText(JSON.stringify(root.launches));
    }

    // A file that is missing or unreadable starts the counts afresh.
    FileView {
        id: store

        path: Quickshell.statePath("launches.json")
        onLoaded: {
            try {
                root.launches = JSON.parse(store.text());
            } catch (e) {
                root.launches = {};
            }
        }
    }
}
