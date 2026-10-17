pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// The outputs or the inputs PipeWire has, leaving out ports nothing is
// plugged into. Clicking one makes it the one in use; the switch is sound or
// the microphone on, the same as the mute beside its slider.
ListCard {
    id: root

    // Outputs, or else inputs.
    property bool output: true

    service: Audio
    switchChecked: root.output ? !Audio.muted : !Audio.micMuted
    // Muting changes nothing about where sound goes, so the list shows
    // regardless, but only once complete: it appears whole rather than
    // growing and shrinking as it fills in.
    listShown: Audio.listsReady
    title: root.output ? "output" : "input"
    items: Audio.offered(root.output)
    emptyText: root.output ? "no outputs" : "no inputs"

    onSwitchToggled: root.output ? Audio.toggleMuted() : Audio.toggleMicMuted()

    delegate: AudioRow {
        id: row

        required property var modelData

        width: ListView.view.width
        node: row.modelData
        onClicked: Audio.select(row.modelData)
    }
}
