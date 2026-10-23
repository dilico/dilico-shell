import QtQuick
import QtQuick.Shapes
import qs.config

// Dark frost, opaque: a lighter corner fading into the ground, and a fine
// grain over both, so it reads as frosted glass rather than flat paint.
//
// The glow climbs only about fifteen shades, so anything that rounds it to
// whole shades on the way draws it as fifteen flat rings. Three things keep
// it smooth. It is composed in a 16-bit float layer, so nothing is rounded
// until the finished frost reaches the 8-bit screen. It is a bright light
// laid on thinly rather than a gradient of its own colours, since a gradient
// is looked up in 8 bits and would arrive in steps even in the layer; a
// light at a tenth's opacity steps a tenth as far. And the grain, drawn in
// the same layer, varies every pixel by at least a shade, so that last
// rounding is dithered instead of banding.
Item {
    id: root

    // Where the light sits, behind the clock, and how far it reaches, from
    // the screen's size, so the composition holds on any screen.
    readonly property real glowX: root.width * 0.75
    readonly property real glowY: root.height * 0.25
    readonly property real glowRadius: root.width * 0.5

    // How thinly the light is laid on. The thinner, the finer its steps, but
    // the brighter it has to be to lift the ground to lockGlow; below about
    // 0.08 it would have to be brighter than white.
    readonly property real lift: 0.1

    // Laid on at `lift`, lifts the ground to lockGlow at the centre.
    readonly property color light: Qt.rgba(root.lit(Colors.lockGround.r, Colors.lockGlow.r), root.lit(Colors.lockGround.g, Colors.lockGlow.g), root.lit(Colors.lockGround.b, Colors.lockGlow.b), 1)

    function lit(ground: real, glow: real): real {
        return ground + (glow - ground) / root.lift;
    }

    // The light a fraction u of the way out, eased so it leaves the centre
    // and meets the ground with no slope. A straight fade stops dead at the
    // ground, and the eye draws a ring where it does.
    function shade(u: real): color {
        const k = u * u * (3 - 2 * u);
        return Qt.rgba(root.light.r, root.light.g, root.light.b, 1 - k);
    }

    layer.enabled: true
    layer.format: ShaderEffectSource.RGBA16F

    Rectangle {
        anchors.fill: parent
        color: Colors.lockGround
    }

    Shape {
        anchors.fill: parent
        opacity: root.lift

        ShapePath {
            strokeColor: "transparent"

            fillGradient: RadialGradient {
                centerX: root.glowX
                centerY: root.glowY
                centerRadius: root.glowRadius
                focalX: root.glowX
                focalY: root.glowY

                GradientStop {
                    position: 0
                    color: root.shade(0)
                }

                GradientStop {
                    position: 0.175
                    color: root.shade(0.25)
                }

                GradientStop {
                    position: 0.35
                    color: root.shade(0.5)
                }

                GradientStop {
                    position: 0.525
                    color: root.shade(0.75)
                }

                GradientStop {
                    position: 0.7
                    color: root.shade(1)
                }
            }

            PathRectangle {
                width: root.width
                height: root.height
            }
        }
    }

    // A 256 px tile of grey noise, faint, at one pixel per pixel. Only fine
    // grain, and every row and column of it averages mid grey: anything
    // coarser, or a row a shade off, repeats every 256 px and shows as
    // blotches in a grid and streaks across the screen. No pixel is pure
    // black or white; those specks are spread over the twelve shades next to
    // them instead, so at this opacity every pixel varies by about a shade
    // and the grain dithers the glow under it.
    Image {
        anchors.fill: parent
        source: "grain.png"
        fillMode: Image.Tile
        smooth: false
        opacity: 0.08
    }
}
