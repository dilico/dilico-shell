pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services
import qs.utils

// One network in the list: its name over its security and signal, and under
// it either a password prompt or a saved network's details. It only shows and
// reports; the list decides what a click does and what is open.
Item {
    id: root

    // Null once NetworkManager drops the network, which it does when the
    // network goes out of range, until the list catches up. Everything here
    // reads it through the defaults below.
    required property var network
    // Whether this row's details are open; the list keeps one open at a time.
    property bool detailsOpen: false

    readonly property string name: root.network?.name ?? ""
    readonly property real strength: root.network?.signalStrength ?? 0
    readonly property bool known: root.network?.known ?? false
    readonly property bool current: root.network?.connected ?? false
    readonly property bool joining: root.network !== null && Network.joining === root.network
    readonly property bool connecting: Network.connecting(root.network)
    readonly property bool expanded: root.joining && (Network.needsPassword || Network.failure !== "")
    // Animates "connecting" the way a spinner would, without the motion.
    property int dots: 0

    signal clicked()
    signal detailsToggled()

    // Raised for the connected network, lit while something is open under it.
    function ground(): color {
        if (root.current)
            return Colors.surfaceRaised;
        return root.expanded || root.detailsOpen ? Colors.surfaceHover : "transparent";
    }

    visible: root.network !== null
    implicitHeight: line.height + (body.visible ? body.implicitHeight : 0)

    Timer {
        running: root.connecting
        interval: 300
        repeat: true
        onTriggered: root.dots = (root.dots + 1) % 4
        onRunningChanged: root.dots = 0
    }

    // Shows the chevron. It covers the whole row, so moving onto the chevron
    // cannot hide it out from under the pointer.
    HoverHandler {
        id: rowHover
    }

    Surface {
        anchors.fill: parent
        radius: Rounding.small
        hovered: pick.hovered && !root.current
        restColor: root.ground()
    }

    Item {
        id: line

        width: parent.width
        height: 46

        Pressable {
            id: pick

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: chevron.visible ? chevron.left : parent.right

            Accessible.name: root.name

            onClicked: root.clicked()

            SignalBars {
                id: bars

                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                lit: Icons.bars(root.strength)
                litColor: root.current ? Colors.text : Colors.textMid
            }

            Column {
                anchors.left: bars.right
                anchors.leftMargin: 10
                anchors.right: status.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Label {
                    width: parent.width
                    text: root.name
                    elide: Text.ElideRight
                    font.weight: root.current ? Font.DemiBold : Font.Normal
                }

                Caption {
                    objectName: "summary"
                    width: parent.width
                    text: `${Network.securityName(root.network)} · ${Format.percent(root.strength)}${root.known && !root.current ? " · saved" : ""}`
                    elide: Text.ElideRight
                }
            }

            Row {
                id: status

                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Caption {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.current || root.connecting
                    text: root.current ? "connected" : `connecting${".".repeat(root.dots)}`
                    color: Colors.textMid
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.current
                    text: Glyphs.check
                }

                Caption {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.current && !root.connecting && Network.secured(root.network)
                    text: Glyphs.lockOutline

                    Accessible.name: "secured"
                }
            }
        }

        // Only a saved network has details. Its place is kept while hidden,
        // so the row does not shift as the pointer comes and goes.
        ChevronButton {
            id: chevron

            objectName: "details"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            visible: root.known
            opacity: rowHover.hovered || root.detailsOpen || root.current ? 1 : 0
            open: root.detailsOpen

            Accessible.name: `${root.detailsOpen ? "hide" : "show"} details for ${root.name}`

            onClicked: root.detailsToggled()
        }
    }

    // The prompt and the details take the same place under the line, inset
    // the same way. Each is loaded only while open: one row has it at a time.
    Column {
        id: body

        anchors.top: line.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        topPadding: 2
        leftPadding: 8
        rightPadding: 8
        bottomPadding: 8
        visible: root.expanded || root.detailsOpen

        Loader {
            width: body.width - body.leftPadding - body.rightPadding
            active: root.expanded
            sourceComponent: prompt
        }

        Loader {
            width: body.width - body.leftPadding - body.rightPadding
            active: root.detailsOpen

            sourceComponent: NetworkDetails {
                network: root.network
                connected: root.current
            }
        }
    }

    Component {
        id: prompt

        Column {
            spacing: 6

            Component.onCompleted: if (Network.needsPassword) password.focusInput()

            Connections {
                target: Network

                function onNeedsPasswordChanged(): void {
                    if (Network.needsPassword)
                        password.focusInput();
                }

                // A rejected password comes back selected, ready to be typed
                // over.
                function onFailureChanged(): void {
                    if (Network.failure !== "" && Network.needsPassword)
                        password.selectAll();
                }
            }

            Item {
                width: parent.width
                height: password.implicitHeight
                visible: Network.needsPassword

                TextField {
                    id: password

                    anchors.left: parent.left
                    anchors.right: connect.left
                    anchors.rightMargin: 6
                    password: true
                    placeholder: "password"

                    Accessible.name: `password for ${root.name}`

                    onAccepted: Network.submit(password.text)
                    onCancelled: Network.cancel()
                }

                Pressable {
                    id: connect

                    anchors.right: parent.right
                    width: connectText.implicitWidth + 24
                    height: parent.height
                    interactive: !Network.busy

                    Accessible.name: `connect to ${root.name}`

                    onClicked: Network.submit(password.text)

                    Surface {
                        anchors.fill: parent
                        radius: Rounding.small
                        active: true
                    }

                    Subtext {
                        id: connectText

                        anchors.centerIn: parent
                        text: Network.busy ? "connecting" : "connect"
                        color: Colors.activeText
                        font.weight: Font.DemiBold
                    }
                }
            }

            Caption {
                width: parent.width
                visible: Network.failure !== ""
                text: Network.failure
                wrapMode: Text.Wrap
                color: Colors.textMid

                Accessible.role: Accessible.AlertMessage
            }
        }
    }
}
