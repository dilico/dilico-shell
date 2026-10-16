import QtQuick
import qs.config

// The second line under something: the date under the weekday, an artist
// under a title, a notification's body. Dimmer and smaller than body text,
// larger than a Caption.
Label {
    id: root

    color: Colors.textDim
    font.pixelSize: Typography.subtextSize
}
