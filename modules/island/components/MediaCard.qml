pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services
import qs.utils

Item {
    id: root

    readonly property bool showProgress: Media.length > 0

    implicitWidth: 360
    // Down to the art, or to the progress line under it, and the padding again.
    implicitHeight: (root.showProgress ? progress.y + progress.height : art.y + art.height) + Spacing.card

    Surface {
        anchors.fill: parent
    }

    ClippingRectangle {
        id: art

        x: Spacing.card
        y: Spacing.card
        width: 48
        height: 48
        radius: Rounding.small
        color: Colors.surfaceRaised

        Image {
            id: cover

            anchors.fill: parent
            source: Media.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 96
            sourceSize.height: 96
            visible: cover.status === Image.Ready
        }

        Label {
            anchors.centerIn: parent
            visible: !cover.visible
            text: Glyphs.play
            color: Colors.textFaint
            font.pixelSize: Typography.iconSize
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 12
        anchors.right: controls.left
        anchors.rightMargin: 8
        anchors.verticalCenter: art.verticalCenter
        spacing: 3

        Label {
            width: parent.width
            text: Media.available ? Media.title : "nothing playing"
            elide: Text.ElideRight
            color: Media.available ? Colors.text : Colors.textDim
            font.weight: Font.DemiBold
        }

        Subtext {
            width: parent.width
            visible: Media.artist !== ""
            text: Media.artist
            elide: Text.ElideRight
        }
    }

    Row {
        id: controls

        anchors.right: parent.right
        anchors.rightMargin: Spacing.card
        anchors.verticalCenter: art.verticalCenter
        spacing: 4
        visible: Media.available

        SkipButton {
            interactive: Media.canGoPrevious
            glyph: Glyphs.previous
            label: "previous track"
            onClicked: Media.previous()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            size: 32
            radius: Rounding.small
            highlighted: true
            glyph: Media.playing ? Glyphs.pause : Glyphs.play
            label: Media.playing ? "pause" : "play"
            onClicked: Media.togglePlaying()
        }

        SkipButton {
            interactive: Media.canGoNext
            glyph: Glyphs.next
            label: "next track"
            onClicked: Media.next()
        }
    }

    Item {
        id: progress

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: art.bottom
        anchors.leftMargin: Spacing.card
        anchors.rightMargin: Spacing.card
        anchors.topMargin: 12
        height: 14
        visible: root.showProgress

        Caption {
            id: positionText

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: Format.playTime(Media.position)
        }

        Track {
            anchors.left: positionText.right
            anchors.leftMargin: 10
            anchors.right: lengthText.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 3
            radius: 2
            value: Media.progress
            fillColor: Colors.textMid
        }

        Caption {
            id: lengthText

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Format.playTime(Media.length)
        }
    }

    // Previous and next: borderless, and dimmed when the player can't skip.
    component SkipButton: IconButton {
        anchors.verticalCenter: parent.verticalCenter
        size: 30
        radius: Rounding.small
        background: "transparent"
        iconColor: interactive ? Colors.textMid : Colors.textFaint
    }
}
