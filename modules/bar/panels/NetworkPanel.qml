pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.modules.bar.components
import qs.services

Item {
    id: root

    // The network being joined, kept past submit so its failure still reports.
    property var target: null
    property bool prompting: false
    // Whether a password typed here has been tried yet, so the first request
    // for one is not reported as a rejection.
    property bool submitted: false
    // True from submit until NetworkManager answers.
    property bool busy: false
    property string error: ""
    property real padding: 10

    // Holds the pill open while the password is typed: the pointer has to
    // leave the surface to reach the keyboard.
    readonly property bool interacting: root.prompting
    readonly property bool wantsKeyboard: root.prompting
    readonly property real contentInset: wifiButton.padding
    readonly property string statusGlyph: Network.enabled ? Glyphs.network : Glyphs.networkOff

    function select(network: var): void {
        root.error = "";
        root.submitted = false;
        if (network.connected)
            return;
        root.target = network;
        // A known network already has its secret stored by NetworkManager.
        if (network.known || !Network.secured(network)) {
            Network.connect(network);
            return;
        }
        root.prompting = true;
    }

    // The form stays up through the attempt: a rejected password has to be
    // correctable, and the failure only arrives after NetworkManager answers.
    function submit(): void {
        if (!root.target || root.busy)
            return;
        root.busy = true;
        root.submitted = true;
        root.error = "";
        attemptTimeout.restart();
        Network.connectWithPassword(root.target, password.text);
    }

    function cancel(): void {
        attemptTimeout.stop();
        // Backstop for an attempt abandoned before any failure arrived: nothing
        // here worked, so no profile should survive it.
        if (root.submitted && root.target && !root.target.connected)
            Network.forget(root.target);
        root.target = null;
        root.prompting = false;
        root.submitted = false;
        root.busy = false;
        root.error = "";
        password.clear();
    }

    implicitWidth: 380
    implicitHeight: column.implicitHeight + root.padding * 2

    onVisibleChanged: if (!visible) root.cancel()
    onPromptingChanged: if (root.prompting) password.focusInput()

    // Scanning costs radio time, so it only runs while the list is on screen.
    Binding {
        target: Network
        property: "scanning"
        value: root.visible && Network.enabled
    }

    Timer {
        running: root.visible && Network.enabled && !root.prompting
        // NetworkManager completes a scan about every 14 seconds and drops
        // requests made sooner, so asking faster than this gains nothing.
        interval: 10000
        repeat: true
        triggeredOnStart: true
        onTriggered: Network.refresh()
    }

    // NetworkManager can leave an attempt hanging, and the form holds an
    // exclusive keyboard grab while it is up.
    Timer {
        id: attemptTimeout

        interval: 20000
        onTriggered: {
            root.busy = false;
            root.error = "Could not connect";
        }
    }

    Connections {
        target: root.target

        function onConnectionFailed(reason: int): void {
            attemptTimeout.stop();
            root.busy = false;
            root.prompting = Network.secured(root.target);

            // Asking for a password nobody has typed yet is the prompt, not a
            // rejection, so it opens the form without an error.
            const asking = Network.needsPassword(reason) && !root.submitted;
            root.error = asking ? "" : Network.failureMessage(reason);

            if (root.submitted) {
                // NetworkManager saves the profile the moment the password is
                // sent, before it learns the password is wrong. Clearing it lets
                // the retry write a fresh one.
                Network.forget(root.target);
                if (root.prompting)
                    password.selectAllInput();
            }
        }

        function onConnectedChanged(): void {
            if (root.target.connected)
                root.cancel();
        }
    }

    Column {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.padding
        // Extra on the right to match the leading glyph's own padding.
        anchors.rightMargin: root.padding + root.contentInset
        anchors.topMargin: root.padding
        spacing: 12

        SectionLabel {
            text: Network.enabled ? "Current network" : "Wi-Fi"
        }

        Row {
            width: parent.width
            spacing: 12

            Icon {
                id: wifiButton

                glyph: root.statusGlyph
                active: !Network.enabled
                activeColor: Colors.textDim
                onClicked: {
                    root.cancel();
                    Network.setEnabled(!Network.enabled);
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - wifiButton.width - parent.spacing
                elide: Text.ElideRight
                text: !Network.enabled ? "Wi-Fi off" : Network.active?.name ?? "Not connected"
                color: Colors.text
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontSizeSmall
            }
        }

        Item {
            width: parent.width
            implicitHeight: availableLabel.implicitHeight
            visible: Network.enabled && !root.prompting

            SectionLabel {
                id: availableLabel

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Network.refreshing ? "Scanning…" : "Available networks"
            }

            Text {
                id: rescan

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Glyphs.refresh
                color: rescanHover.hovered ? Colors.accent : Colors.textDim
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontSizeSmall

                RotationAnimation on rotation {
                    running: Network.refreshing
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1200

                    onRunningChanged: if (!running) rescan.rotation = 0
                }

                HoverHandler {
                    id: rescanHover

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: Network.refresh()
                }
            }
        }

        Flickable {
            width: parent.width
            height: Math.min(list.implicitHeight, 280)
            contentHeight: list.implicitHeight
            clip: true
            visible: Network.enabled && !root.prompting
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list

                width: parent.width
                spacing: 6

                Repeater {
                    model: Network.networks

                    delegate: NetworkRow {
                        required property var modelData

                        width: parent.width
                        network: modelData
                        onSelected: root.select(modelData)
                        onForgotten: Network.forget(modelData)
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 12
            visible: root.prompting

            SectionLabel {
                text: `Join ${root.target?.name ?? ""}`
            }

            TextField {
                id: password

                width: parent.width
                password: true
                placeholder: "Password"
                onAccepted: root.submit()
                onCancelled: root.cancel()
            }

            Item {
                width: parent.width
                implicitHeight: actions.implicitHeight

                Text {
                    anchors.left: parent.left
                    anchors.right: actions.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    visible: root.error !== ""
                    text: root.error
                    color: Colors.textDim
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontSizeSmall
                }

                Row {
                    id: actions

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Text {
                        text: "Cancel"
                        color: cancelHover.hovered ? Colors.accent : Colors.textDim
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontSizeSmall

                        HoverHandler {
                            id: cancelHover

                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: root.cancel()
                        }
                    }

                    Text {
                        text: root.busy ? "Connecting…" : "Connect"
                        color: root.busy ? Colors.textDim : connectHover.hovered ? Colors.accent : Colors.text
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontSizeSmall

                        HoverHandler {
                            id: connectHover

                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: root.submit()
                        }
                    }
                }
            }
        }
    }
}
