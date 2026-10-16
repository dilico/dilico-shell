import QtQuick

// Anything that is clicked. Owns the hover, the hand cursor and the tap, so
// every control answers the pointer the same way; what builds on it only
// draws. Taps go through a TapHandler, which is why the island's backdrop has
// to be a MouseArea (conventions §6).
Item {
    id: root

    // False makes it inert: no hover, no hand cursor, no click.
    property bool interactive: true
    readonly property alias hovered: hover.hovered

    signal clicked()

    Accessible.role: Accessible.Button
    Accessible.onPressAction: if (root.interactive) root.clicked()

    HoverHandler {
        id: hover

        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.interactive
        onTapped: root.clicked()
    }
}
