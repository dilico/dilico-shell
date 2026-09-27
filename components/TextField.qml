import QtQuick
import qs.config

Item {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool password: false
    property real padding: 14
    property real radius: 10

    signal accepted(string text)
    signal cancelled()

    function focusInput(): void {
        input.forceActiveFocus();
    }

    function selectAllInput(): void {
        input.forceActiveFocus();
        input.selectAll();
    }

    function clear(): void {
        input.text = "";
    }

    implicitWidth: 200
    implicitHeight: input.implicitHeight + root.padding * 2

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Colors.surface
        border.width: 1
        border.color: input.activeFocus ? Colors.accent : Colors.border

        Behavior on border.color {
            ColorAnimation {
                duration: Animations.durationShort
                easing.type: Animations.easingType
            }
        }
    }

    Text {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: root.placeholder
        color: Colors.textDim
        font.family: Typography.fontFamily
        font.pixelSize: Typography.fontSizeSmall
    }

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        verticalAlignment: Text.AlignVCenter
        clip: true
        selectByMouse: true
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        color: Colors.text
        selectionColor: Colors.accent
        selectedTextColor: Colors.background
        font.family: Typography.fontFamily
        font.pixelSize: Typography.fontSizeSmall

        onAccepted: root.accepted(input.text)
        Keys.onEscapePressed: root.cancelled()
    }
}
