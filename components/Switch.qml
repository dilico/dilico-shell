import QtQuick
import qs.config

// An on/off switch. Displays `checked`, never writes it: the owner turns
// clicked() into a change, as with Slider.
Pressable {
    id: root

    property bool checked: false

    readonly property real knobSize: 14
    readonly property real inset: 3

    implicitWidth: 34
    implicitHeight: 20

    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: root.checked

    Surface {
        anchors.fill: parent
        radius: Rounding.small
        active: root.checked
        restColor: Colors.surfaceRaised

        Rectangle {
            x: root.checked ? root.width - root.knobSize - root.inset : root.inset
            anchors.verticalCenter: parent.verticalCenter
            width: root.knobSize
            height: root.knobSize
            // One less than the track, so the two corners look concentric.
            radius: Rounding.small - 1
            color: root.checked ? Colors.activeText : Colors.textDim

            Behavior on x {
                NumberAnimation {
                    duration: Animations.durationShort
                    easing.type: Animations.easingType
                }
            }
        }
    }
}
