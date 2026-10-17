pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config

// A row in one of the dashboard's lists: something on the left, a name over a
// line of detail, what it is doing on the right, and room under it for a
// prompt or details. It only shows and reports; its list decides what a click
// does and what is open.
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    // The one in use: a raised ground, a bold name, and "connected".
    property bool current: false
    // What it is busy doing, such as "connecting", or "". It shows on the
    // right with dots counting up the way a spinner would, without the motion.
    property string busyText: ""
    // A small glyph at the far right, such as a padlock, and what it means.
    property string badge: ""
    property string badgeName: ""
    property Component leading: null
    // A chevron opens the details; the list keeps one row's open at a time.
    property bool hasDetails: false
    property bool detailsOpen: false
    // What shows under the row while it is open: its details, unless the row
    // has something else to show there.
    property Component body: null
    property bool bodyOpen: root.detailsOpen

    readonly property bool busy: root.busyText !== ""
    property int dots: 0

    signal clicked()
    signal detailsToggled()

    // Raised for the one in use, lit while something is open under it.
    function ground(): color {
        if (root.current)
            return Colors.surfaceRaised;
        return root.bodyOpen ? Colors.surfaceHover : "transparent";
    }

    function statusText(): string {
        if (root.current)
            return "connected";
        return root.busy ? `${root.busyText}${".".repeat(root.dots)}` : "";
    }

    implicitHeight: line.height + (root.bodyOpen ? under.implicitHeight : 0)

    Timer {
        running: root.busy
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

            Accessible.name: root.title

            onClicked: root.clicked()

            Loader {
                id: lead

                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: root.leading
            }

            Column {
                anchors.left: lead.right
                anchors.leftMargin: 10
                anchors.right: status.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Label {
                    width: parent.width
                    text: root.title
                    elide: Text.ElideRight
                    font.weight: root.current ? Font.DemiBold : Font.Normal
                }

                Caption {
                    objectName: "summary"
                    width: parent.width
                    text: root.subtitle
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
                    visible: text !== ""
                    text: root.statusText()
                    color: Colors.textMid
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.current
                    text: Glyphs.check
                }

                Caption {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.badge !== ""
                    text: root.badge

                    Accessible.name: root.badgeName
                }
            }
        }

        // Its place is kept while hidden, so the row does not shift as the
        // pointer comes and goes.
        ChevronButton {
            id: chevron

            objectName: "details"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            visible: root.hasDetails
            opacity: rowHover.hovered || root.detailsOpen || root.current ? 1 : 0
            open: root.detailsOpen

            Accessible.name: `${root.detailsOpen ? "hide" : "show"} details for ${root.title}`

            onClicked: root.detailsToggled()
        }
    }

    // Loaded only while open: one row has something open at a time.
    Column {
        id: under

        anchors.top: line.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        topPadding: 2
        leftPadding: 8
        rightPadding: 8
        bottomPadding: 8
        visible: root.bodyOpen

        Loader {
            width: under.width - under.leftPadding - under.rightPadding
            active: root.bodyOpen
            sourceComponent: root.body
        }
    }
}
