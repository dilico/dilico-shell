pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services
import qs.utils

// The heaviest processes as a pane, by cpu or by memory: a heading over each
// column picks which, and the column it is sorted by is the bright one. As
// many as fit, so nothing scrolls under a list that re-sorts every sample.
// Clicking one offers to end it, politely or by force.
PaneCard {
    id: root

    // "cpu" or "memory". Displayed, never written: a heading reports
    // sortPicked, and the owner decides.
    property string sortBy: "cpu"

    // The process clicked, offered to end, by pid, or 0. While there is one
    // the order holds still, so the row under the pointer stays the one
    // offered; the figures stay live, and a process that exits drops out.
    property int picked: 0
    property var heldOrder: []

    readonly property var live: Processes.ready ? Processes.top(root.sortBy, root.shown) : []
    readonly property var rows: root.picked !== 0 ? root.heldOrder.map(pid => Processes.processes.find(p => p.pid === pid)).filter(p => p !== undefined) : root.live
    readonly property int rowHeight: 26
    readonly property int valueWidth: 52
    // Whatever the column headings leave.
    readonly property int shown: Math.max(0, Math.floor((list.height - headings.height) / root.rowHeight))

    signal sortPicked(string by)

    // Clicking the one offered takes the offer back.
    function pick(pid: int): void {
        if (root.picked === 0)
            root.heldOrder = root.live.map(p => p.pid);
        root.picked = root.picked === pid ? 0 : pid;
    }

    function end(force: bool): void {
        Processes.end(root.picked, force);
        root.picked = 0;
    }

    title: "processes"

    // A list held in one order would be wrong in the other.
    onSortByChanged: root.picked = 0
    // Nothing is left to offer once the process has gone.
    onRowsChanged: if (root.picked !== 0 && !root.rows.some(p => p.pid === root.picked))
        root.picked = 0

    Watch {
        service: Processes
    }

    Column {
        id: list

        anchors.fill: parent

        Item {
            id: headings

            width: parent.width
            height: root.rowHeight

            // The size of the words that sort, so the headings read as a row.
            Subtext {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "process"
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                Heading {
                    objectName: "cpu"
                    width: root.valueWidth
                    text: "cpu"
                    selected: root.sortBy === "cpu"
                    onClicked: root.sortPicked("cpu")
                }

                Heading {
                    objectName: "memory"
                    width: root.valueWidth
                    text: "mem"
                    selected: root.sortBy === "memory"
                    onClicked: root.sortPicked("memory")
                }
            }
        }

        // By position, so the rows stay put from one sample to the next and
        // only their text changes: a fresh list for a model would rebuild
        // them every sample, and drop the hover under the pointer.
        Repeater {
            objectName: "rows"
            model: root.rows.length

            Item {
                id: row

                required property int index

                // Null for a moment while the rows shrink.
                readonly property var modelData: root.rows[row.index] ?? null
                readonly property bool offered: row.modelData !== null && root.picked === row.modelData.pid

                width: list.width
                height: root.rowHeight

                // Raised while offered, the way a list's row in use is.
                Surface {
                    anchors.fill: parent
                    radius: Rounding.small
                    hovered: pick.hovered && !row.offered
                    restColor: row.offered ? Colors.surfaceRaised : "transparent"
                }

                // Stops short of the words to end it while they show: a tap
                // on one would otherwise reach this too, and take the offer
                // back (conventions §6).
                Pressable {
                    id: pick

                    objectName: "pick"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: row.offered ? actions.left : parent.right

                    Accessible.name: row.modelData?.name ?? ""

                    onClicked: root.pick(row.modelData?.pid ?? 0)

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: values.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: row.modelData?.name ?? ""
                    }

                    Row {
                        id: values

                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !row.offered

                        Value {
                            width: root.valueWidth
                            text: Format.percentTenths(row.modelData?.cpu ?? 0)
                            selected: root.sortBy === "cpu"
                        }

                        Value {
                            width: root.valueWidth
                            text: Format.size(row.modelData?.memory ?? 0)
                            selected: root.sortBy === "memory"
                        }
                    }
                }

                Row {
                    id: actions

                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.offered
                    spacing: 18

                    TextButton {
                        objectName: "end"
                        text: "end"
                        accessibleName: `end ${row.modelData?.name ?? ""}`
                        onClicked: root.end(false)
                    }

                    TextButton {
                        objectName: "kill"
                        text: "kill"
                        accessibleName: `kill ${row.modelData?.name ?? ""}`
                        onClicked: root.end(true)
                    }
                }
            }
        }
    }

    Subtext {
        anchors.centerIn: parent
        visible: !Processes.ready
        text: "measuring"
    }

    // A column's heading, at the right of its column: the word that sorts by
    // it.
    component Heading: Item {
        id: heading

        property alias text: button.text
        property alias selected: button.selected

        signal clicked()

        height: button.implicitHeight

        TextButton {
            id: button

            anchors.right: parent.right
            accessibleName: `sort by ${heading.text}`
            onClicked: heading.clicked()
        }
    }

    // A value in a column, bright in the column sorted by.
    component Value: Caption {
        id: value

        property bool selected: false

        horizontalAlignment: Text.AlignRight
        color: value.selected ? Colors.text : Colors.textDim
    }
}
