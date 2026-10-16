import QtQuick
import qs.config

// Text in the shell's font. Colour and size default to body text; override
// either where the text is something else.
Text {
    id: root

    color: Colors.text
    font.family: Typography.fontFamily
    font.pixelSize: Typography.bodySize
}
