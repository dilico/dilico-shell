pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services
import qs.utils

// One network: its signal, its name over its security and strength, and
// under it a password prompt or a saved network's details.
ListRow {
    id: root

    // Null once NetworkManager drops the network, which it does when the
    // network goes out of range, until the list catches up. Everything here
    // reads it through the defaults below.
    required property var network

    readonly property real strength: root.network?.signalStrength ?? 0
    readonly property bool known: root.network?.known ?? false
    readonly property bool joining: root.network !== null && Network.joining === root.network
    readonly property bool expanded: root.joining && (Network.needsPassword || Network.failure !== "")

    visible: root.network !== null
    title: root.network?.name ?? ""
    subtitle: `${Network.securityName(root.network)} · ${Format.percent(root.strength)}${root.known && !root.current ? " · saved" : ""}`
    current: root.network?.connected ?? false
    busyText: Network.connecting(root.network) ? "connecting" : ""
    badge: !root.current && !root.busy && Network.secured(root.network) ? Glyphs.lockOutline : ""
    badgeName: "secured"
    hasDetails: root.known
    bodyOpen: root.expanded || root.detailsOpen
    body: root.expanded ? prompt : details

    leading: SignalBars {
        lit: Icons.bars(root.strength)
        litColor: root.current ? Colors.text : Colors.textMid
    }

    Component {
        id: details

        NetworkDetails {
            network: root.network
            connected: root.current
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

                    Accessible.name: `password for ${root.title}`

                    onAccepted: Network.submit(password.text)
                    onCancelled: Network.cancel()
                }

                Pressable {
                    id: connect

                    anchors.right: parent.right
                    width: connectText.implicitWidth + 24
                    height: parent.height
                    interactive: !Network.busy

                    Accessible.name: `connect to ${root.title}`

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
