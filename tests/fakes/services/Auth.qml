pragma Singleton

import QtQuick
import Quickshell

// Stands in for services/Auth in tests: the same interface as far as the lock
// screen uses it, recording each password it is asked to check.
Singleton {
    id: root

    property string user: "el_scrondo"
    property bool busy: false
    property string failure: ""
    // Each password checked; reset by tests.
    property var calls: []

    signal succeeded()

    function check(password: string): void {
        root.calls.push(password);
    }
}
