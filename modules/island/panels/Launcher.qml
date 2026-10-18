pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// The apps, searched as you type: a field, then every match, best first, with
// the first one picked. Up and down move the pick through all of them, and
// the list scrolls to keep it in sight, as the wheel scrolls it too; Enter
// launches it, Escape backs out. Always a page of matches tall, so the island
// does not change size under the typing.
Item {
    id: root

    readonly property int padding: 14
    // Between the field and the list.
    readonly property int gap: 10
    readonly property int rowHeight: 44
    readonly property int pageSize: 8
    readonly property var matches: Apps.search(field.text)

    // Which match Enter launches, and the one shown picked. Back to the best
    // one whenever the query changes.
    property int current: 0

    signal launched()
    signal cancelled()

    function move(by: int): void {
        root.current = Math.max(0, Math.min(root.matches.length - 1, root.current + by));
    }

    function launch(app: var): void {
        Apps.launch(app);
        root.launched();
    }

    function launchCurrent(): void {
        if (root.matches.length > 0)
            root.launch(root.matches[root.current]);
    }

    implicitWidth: 520
    implicitHeight: root.padding * 2 + field.height + root.gap + list.height

    // A new query starts from the best match at the top, wherever the wheel
    // had scrolled to.
    onMatchesChanged: {
        root.current = 0;
        list.positionViewAtBeginning();
    }
    // Scrolls only as far as it must to show the pick, so moving within the
    // page leaves the page where it is.
    onCurrentChanged: list.positionViewAtIndex(root.current, ListView.Contain)

    // The key that opened it is not a click, so the field takes the keyboard
    // itself, once the window holds it.
    Component.onCompleted: field.focusInput()

    Label {
        id: searchGlyph

        anchors.left: parent.left
        anchors.leftMargin: root.padding + 4
        anchors.verticalCenter: field.verticalCenter
        text: Glyphs.search
        color: Colors.textDim
        font.pixelSize: Typography.iconSize
    }

    TextField {
        id: field

        objectName: "query"
        anchors.left: searchGlyph.right
        anchors.leftMargin: 6
        anchors.right: parent.right
        anchors.rightMargin: root.padding
        anchors.top: parent.top
        anchors.topMargin: root.padding
        height: 36
        placeholder: "search apps"

        // The field has no use for up and down, so they move the pick.
        Keys.onUpPressed: root.move(-1)
        Keys.onDownPressed: root.move(1)

        onAccepted: root.launchCurrent()
        onCancelled: root.cancelled()
    }

    ListView {
        id: list

        objectName: "matches"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: field.bottom
        anchors.topMargin: root.gap
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        height: root.rowHeight * root.pageSize
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: rows

        delegate: Pressable {
            id: match

            required property var modelData
            required property int index

            readonly property bool picked: match.index === root.current

            width: list.width
            height: root.rowHeight

            Accessible.name: match.modelData.name

            onClicked: root.launch(match.modelData)

            Surface {
                anchors.fill: parent
                radius: Rounding.small
                hovered: match.hovered && !match.picked
                restColor: match.picked ? Colors.surfaceRaised : "transparent"
            }

            Image {
                id: icon

                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                sourceSize.width: 28
                sourceSize.height: 28
                source: Apps.icon(match.modelData)
                asynchronous: true
            }

            Column {
                anchors.left: icon.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: match.modelData.name
                }

                Caption {
                    id: description

                    width: parent.width
                    visible: description.text !== ""
                    elide: Text.ElideRight
                    text: match.modelData.genericName || match.modelData.comment
                }
            }
        }
    }

    // Keeps a row for each app from one keystroke to the next, so a row that
    // stays is not rebuilt and its icon does not reload.
    ScriptModel {
        id: rows

        values: root.matches
    }

    Subtext {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: list.top
        anchors.topMargin: root.rowHeight
        visible: root.matches.length === 0
        text: "no apps match"
    }
}
