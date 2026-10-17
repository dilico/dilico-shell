import QtQuick
import qs.config

// One line of text input. It takes Escape for itself before any shortcut
// sees it, so Escape backs out of the field rather than closing whatever holds
// it (conventions §6).
Item {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool password: false

    signal accepted()
    signal cancelled()

    function focusInput(): void {
        input.forceActiveFocus();
    }

    function selectAll(): void {
        input.forceActiveFocus();
        input.selectAll();
    }

    function clear(): void {
        input.clear();
    }

    implicitWidth: 200
    implicitHeight: 32

    Accessible.role: Accessible.EditableText
    Accessible.name: root.placeholder
    Accessible.passwordEdit: root.password

    // Cut into whatever it sits on, like the slider's knob ring.
    Rectangle {
        anchors.fill: parent
        radius: Rounding.small
        color: Colors.island
        border.width: 1
        border.color: input.activeFocus ? Colors.textDim : Colors.outline

        Behavior on border.color {
            ColorAnimation {
                duration: Animations.durationShort
                easing.type: Animations.easingType
            }
        }
    }

    Label {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: root.placeholder
        color: Colors.textDim
    }

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        selectByMouse: true
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        color: Colors.text
        selectionColor: Colors.textFaint
        selectedTextColor: Colors.text
        font.family: Typography.fontFamily
        font.pixelSize: Typography.bodySize

        onAccepted: root.accepted()
        Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Escape
        Keys.onEscapePressed: root.cancelled()
    }
}
