pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services
import qs.utils

// The monitors plugged in, as a pane: a map of where they sit, on which one
// is dragged beside another, and the modes of the one picked on it. A new
// mode is on trial, and the header offers to keep it while it counts down to
// putting the old one back.
PaneCard {
    id: root

    // The monitor picked on the map, by port, or "" for the first.
    property string picked: ""

    readonly property var current: Displays.monitors.find(m => m.name === root.picked) ?? Displays.monitors[0] ?? null
    readonly property var modes: root.current?.modes ?? []

    function label(m: var): string {
        return m === null ? "" : Format.monitor(m.builtIn, m.model, m.name);
    }

    // Where a monitor dragged `by` pixels on the map goes on the layout.
    function drop(rect: var, by: point): void {
        const scale = map.fit.scale;
        Displays.move(rect.name, rect.x + by.x / scale, rect.y + by.y / scale);
    }

    title: Displays.pending ? "keep this mode?" : "displays"

    trailing: [
        TextButton {
            objectName: "keep"
            anchors.verticalCenter: parent.verticalCenter
            visible: Displays.pending
            text: "keep"
            onClicked: Displays.keep()
        },
        TextButton {
            objectName: "undo"
            anchors.verticalCenter: parent.verticalCenter
            visible: Displays.pending
            text: `undo ${Displays.secondsLeft}`
            accessibleName: "undo"
            onClicked: Displays.revert()
        }
    ]

    Watch {
        service: Displays
    }

    Item {
        id: map

        // Holds still while one is dragged, since the layout only changes at
        // the drop.
        readonly property var fit: Arrange.fit(Displays.layout, map.width, map.height, 8)

        objectName: "map"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 112

        // By position, so a monitor keeps its tile as the layout changes.
        Repeater {
            objectName: "tiles"
            model: Displays.layout.length

            Item {
                id: tile

                required property int index

                // The layout is the monitors' rects, in their order.
                readonly property var rect: Displays.layout[tile.index] ?? null
                readonly property var monitor: Displays.monitors[tile.index] ?? null
                readonly property string label: root.label(tile.monitor)
                readonly property bool picked: tile.monitor === root.current
                // How far it has been dragged, until it is dropped.
                property point moved: Qt.point(0, 0)

                x: map.fit.x + (tile.rect?.x ?? 0) * map.fit.scale + tile.moved.x
                y: map.fit.y + (tile.rect?.y ?? 0) * map.fit.scale + tile.moved.y
                z: drag.active ? 1 : 0
                width: (tile.rect?.width ?? 0) * map.fit.scale
                height: (tile.rect?.height ?? 0) * map.fit.scale

                // Alone, it has nowhere to go.
                DragHandler {
                    id: drag

                    target: null
                    enabled: Displays.monitors.length > 1
                    cursorShape: Qt.ClosedHandCursor
                    onActiveTranslationChanged: {
                        if (drag.active)
                            tile.moved = drag.activeTranslation;
                    }
                    onActiveChanged: {
                        if (drag.active) {
                            root.picked = tile.rect.name;
                            return;
                        }
                        root.drop(tile.rect, tile.moved);
                        tile.moved = Qt.point(0, 0);
                    }
                }

                // A tap picks it; a drag takes over from the tap.
                Pressable {
                    objectName: "pick"
                    anchors.fill: parent

                    Accessible.name: tile.label

                    onClicked: root.picked = tile.rect.name
                }

                Surface {
                    anchors.fill: parent
                    radius: Rounding.small
                    restColor: tile.picked ? Colors.surfaceRaised : Colors.surfaceHover
                    border.width: 1
                    border.color: tile.picked ? Colors.textMid : Colors.outline
                }

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 8

                    Caption {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: tile.label
                        color: tile.picked ? Colors.text : Colors.textMid
                    }

                    Caption {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: Format.resolution(tile.monitor?.width ?? 0, tile.monitor?.height ?? 0)
                    }
                }
            }
        }
    }

    Item {
        id: about

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: map.bottom
        anchors.topMargin: 6
        height: 24

        Label {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.label(root.current)
            font.weight: Font.DemiBold
        }

        Caption {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.current?.name ?? ""
        }
    }

    // By position, so a new reading of the same modes keeps the list where
    // it was scrolled to.
    ListView {
        objectName: "modes"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: about.bottom
        anchors.topMargin: 2
        anchors.bottom: parent.bottom
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.modes.length

        delegate: Item {
            id: row

            required property int index

            // Null for a moment while the list shrinks.
            readonly property var mode: root.modes[row.index] ?? null
            readonly property bool active: row.mode !== null && MonitorRules.sameMode(row.mode, root.current)
            readonly property string size: Format.resolution(row.mode?.width ?? 0, row.mode?.height ?? 0)
            readonly property string rate: Format.refresh(row.mode?.refresh ?? 0)

            width: ListView.view.width
            height: 28

            Surface {
                anchors.fill: parent
                radius: Rounding.small
                hovered: pick.hovered && !row.active
                restColor: row.active ? Colors.surfaceRaised : "transparent"
            }

            Pressable {
                id: pick

                objectName: "pick"
                anchors.fill: parent
                interactive: !row.active

                Accessible.name: `${row.size} at ${row.rate}`

                onClicked: Displays.setMode(root.current.name, row.mode)
            }

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: row.size
                font.weight: row.active ? Font.DemiBold : Font.Normal
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Caption {
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.rate
                    color: row.active ? Colors.textMid : Colors.textDim
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.active
                    text: Glyphs.check
                }
            }
        }
    }

    Subtext {
        anchors.centerIn: parent
        visible: Displays.monitors.length === 0
        text: "reading"
    }
}
