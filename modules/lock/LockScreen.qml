import QtQuick
import qs.components
import qs.config
import qs.modules.lock.components
import qs.services
import qs.utils

// The lock screen on one screen: a big clock and the date in the top corner,
// the password as a terminal prompt in the bottom one, and battery, wifi and
// caps lock across from it.
Item {
    id: root

    required property date date

    // How far everything sits in from the screen's edges.
    readonly property int margin: 96

    // Shown over the prompt while a check runs or after one fails; "" hides
    // it, which is most of the time.
    function notice(): string {
        if (Auth.busy)
            return "checking";
        return Auth.failure;
    }

    function wifiText(): string {
        if (!Network.enabled)
            return "wifi off";
        return Network.connected ? "wifi" : "no wifi";
    }

    // The prompt empties as the password goes to be checked, so a wrong one
    // is typed again from nothing.
    function submit(): void {
        Auth.check(prompt.text);
        prompt.clear();
    }

    // The session lock hands this surface the keyboard; the prompt takes it.
    Component.onCompleted: prompt.focusInput()

    Watch {
        service: Keyboard
    }

    Frost {
        anchors.fill: parent
    }

    Label {
        id: clockLabel

        objectName: "clock"
        anchors.right: parent.right
        anchors.rightMargin: root.margin
        anchors.top: parent.top
        anchors.topMargin: 64
        text: Format.time(root.date)
        font.pixelSize: Typography.lockClockSize
        font.weight: Font.Thin
        font.letterSpacing: -12
    }

    // Hung from the digits' baseline rather than the label's box, which the
    // font pads with a line's worth of room below them.
    Label {
        objectName: "date"
        anchors.right: parent.right
        anchors.rightMargin: root.margin
        anchors.top: clockLabel.baseline
        anchors.topMargin: 24
        text: Format.date(root.date, "ddd d MMM yyyy")
        color: Colors.textDim
        font.pixelSize: Typography.lockDateSize
    }

    Label {
        id: noticeLabel

        objectName: "notice"
        anchors.left: prompt.left
        anchors.bottom: prompt.top
        anchors.bottomMargin: 12
        visible: noticeLabel.text !== ""
        text: root.notice()
        color: Colors.textMid
        font.pixelSize: Typography.lockPromptSize
    }

    PromptLine {
        id: prompt

        anchors.left: parent.left
        anchors.leftMargin: root.margin
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.margin
        user: Auth.user
        busy: Auth.busy
        onAccepted: root.submit()
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: root.margin
        anchors.verticalCenter: prompt.verticalCenter
        spacing: 28

        Label {
            visible: Battery.available
            text: Format.percent(Battery.level)
            color: Colors.textDim
        }

        Label {
            text: root.wifiText()
            color: Colors.textDim
        }

        // Caps lock on is the one thing here worth noticing.
        Label {
            objectName: "caps"
            text: Keyboard.capsLock ? "caps on" : "caps off"
            color: Keyboard.capsLock ? Colors.text : Colors.textDim
            font.weight: Keyboard.capsLock ? Font.DemiBold : Font.Normal
        }
    }
}
