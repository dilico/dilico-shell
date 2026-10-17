import QtQuick
import qs.config

// A word that does something when clicked: "clear", "forget". Dim at rest,
// full colour under the pointer. It is as big as the word, so it lines up like
// any text; the hit area reaches a little past it all round.
Item {
    id: root

    property string text: ""
    // What it does, for assistive tech, when the word alone does not say.
    property string accessibleName: root.text
    readonly property alias hovered: hit.hovered

    signal clicked()

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Pressable {
        id: hit

        anchors.fill: parent
        anchors.margins: -6

        Accessible.name: root.accessibleName

        onClicked: root.clicked()
    }

    Subtext {
        id: label

        text: root.text
        color: root.hovered ? Colors.text : Colors.textDim
    }
}
