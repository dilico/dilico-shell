import QtQuick
import qs.components
import qs.config

// The password as a terminal prompt: the user's name, "❯ password:", a dot
// for each character typed and a block cursor, coloured as the zsh prompt
// is. Escape empties it.
Row {
    id: root

    property string user: ""
    property alias text: input.text
    // A check is under way: the cursor stops and the line takes no typing.
    property bool busy: false

    signal accepted()

    function focusInput(): void {
        input.forceActiveFocus();
    }

    function clear(): void {
        input.clear();
    }

    // A terminal's blink: on and off, not a fade. Steady while checking, as
    // a shell that is busy shows no prompt to type at.
    Timer {
        running: input.activeFocus && !root.busy
        interval: 500
        repeat: true
        onTriggered: block.visible = !block.visible
        onRunningChanged: block.visible = true
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: root.user
        font.pixelSize: Typography.lockPromptSize
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: ` ${Glyphs.prompt} password: `
        color: Colors.textDim
        font.pixelSize: Typography.lockPromptSize
    }

    // Its own cursor is hidden: the block after it stands in, the way a
    // terminal's does.
    TextInput {
        id: input

        objectName: "password"
        anchors.verticalCenter: parent.verticalCenter
        echoMode: TextInput.Password
        passwordCharacter: Glyphs.passwordDot
        readOnly: root.busy
        cursorDelegate: Item {}
        color: Colors.textDim
        font.family: Typography.fontFamily
        font.pixelSize: Typography.lockPromptSize
        font.letterSpacing: 2

        Accessible.role: Accessible.EditableText
        Accessible.name: "password"
        Accessible.passwordEdit: true

        onAccepted: root.accepted()
        Keys.onEscapePressed: input.clear()
    }

    Rectangle {
        id: block

        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(Typography.lockPromptSize * 0.6)
        height: Math.round(Typography.lockPromptSize * 1.2)
        color: Colors.text
    }
}
