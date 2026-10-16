pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification daemon. Owning org.freedesktop.Notifications is exclusive:
// while dilico runs, no other daemon (mako, dunst) can, and vice versa.
Singleton {
    id: root

    // Newest first.
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: server.trackedNotifications.values.length

    // When each arrived, keyed by id, in ms since the epoch. The spec carries
    // no timestamp. An entry lives exactly as long as its notification.
    //
    // Written in place, never reassigned: an entry is in before its
    // notification is tracked, so nothing that shows one can read it early,
    // and nothing needs telling when it changes.
    readonly property var arrived: ({})

    function clear(): void {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    // 0 for a notification that arrived before the last reload.
    function arrivedAt(notification: var): real {
        return root.arrived[notification?.id] ?? 0;
    }

    function forget(id: int): void {
        delete root.arrived[id];
    }

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        actionsSupported: false
        imageSupported: false
        persistenceSupported: true

        onNotification: notification => {
            const id = notification.id;
            root.arrived[id] = Date.now();
            notification.closed.connect(() => root.forget(id));
            notification.tracked = true;
        }
    }
}
