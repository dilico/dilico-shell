pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.utils

// The cable, while one is connected: its speed and address, and under it the
// adapter.
ListRow {
    id: root

    title: "wired"
    subtitle: Format.parts([Format.linkSpeed(Network.wiredDevice?.linkSpeed ?? 0), Network.wiredAddress])
    glyph: Glyphs.wired
    current: true
    hasDetails: true
    body: details

    Component {
        id: details

        Facts {
            facts: [
                ["interface", Network.wiredDevice?.name ?? ""],
                ["mac address", Network.wiredDevice?.address ?? ""]
            ]
        }
    }
}
