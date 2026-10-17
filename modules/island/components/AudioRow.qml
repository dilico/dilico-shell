pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.utils

// One output or input: what kind it is, its name over where it is and its
// level.
ListRow {
    id: root

    // Null once PipeWire drops the node, until the list catches up.
    required property var node

    function level(): string {
        return root.node?.audio?.muted ? "muted" : Format.percent(root.node?.audio?.volume ?? 0);
    }

    visible: root.node !== null
    title: Audio.name(root.node)
    subtitle: [Audio.where(root.node), root.level()].filter(part => part !== "").join(" · ")
    current: Audio.inUse(root.node)
    currentText: "in use"
    glyph: Icons.device(Audio.kind(root.node))
}
