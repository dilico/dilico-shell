import QtQuick
import QtQuick.Shapes
import qs.config

// Dark frost, opaque: a lighter corner fading into the ground, and a fine
// grain over both, so it reads as frosted glass rather than flat paint.
Item {
    id: root

    // Where the light sits, behind the clock, and how far it reaches, from
    // the screen's size, so the composition holds on any screen.
    readonly property real glowX: root.width * 0.75
    readonly property real glowY: root.height * 0.25
    readonly property real glowRadius: root.width * 0.5

    Rectangle {
        anchors.fill: parent
        color: Colors.lockGround
    }

    Shape {
        anchors.fill: parent

        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            startX: 0
            startY: 0

            fillGradient: RadialGradient {
                centerX: root.glowX
                centerY: root.glowY
                centerRadius: root.glowRadius
                focalX: root.glowX
                focalY: root.glowY

                GradientStop {
                    position: 0
                    color: Colors.lockGlow
                }

                GradientStop {
                    position: 0.7
                    color: Colors.lockGround
                }
            }

            PathLine {
                x: root.width
                y: 0
            }

            PathLine {
                x: root.width
                y: root.height
            }

            PathLine {
                x: 0
                y: root.height
            }
        }
    }

    // A 256 px tile of grey noise, faint, at one pixel per pixel.
    Image {
        anchors.fill: parent
        source: "grain.png"
        fillMode: Image.Tile
        smooth: false
        opacity: 0.08
    }
}
