import QtQuick

// Keeps a polled service polling for as long as this exists. A count rather
// than a flag, so two things showing the same numbers can come and go in any
// order without one switching off the other's.
QtObject {
    id: root

    // A service with an int `watchers`.
    required property var service

    Component.onCompleted: root.service.watchers++
    Component.onDestruction: root.service.watchers--
}
