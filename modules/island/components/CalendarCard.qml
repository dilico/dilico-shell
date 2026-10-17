pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.utils

// The month as a pane: its name and the way to the months either side in
// the header, then its weeks with today marked.
PaneCard {
    id: root

    required property date today
    // Months from today's: 0 is this month. Counted from today rather than
    // held as a date, so the page follows the clock over midnight.
    property int offset: 0

    readonly property date first: Calendar.month(root.today, root.offset)
    readonly property int firstDay: Qt.locale().firstDayOfWeek
    // Seven rows: the weekday names, then six weeks.
    readonly property real cellWidth: grid.width / 7
    readonly property real cellHeight: grid.height / 7

    title: Format.date(root.first, "MMMM yyyy")
    trailing: [
        TextButton {
            objectName: "thisMonth"
            anchors.verticalCenter: parent.verticalCenter
            visible: root.offset !== 0
            text: "today"
            accessibleName: "this month"
            onClicked: root.offset = 0
        },
        HeaderButton {
            objectName: "previous"
            glyph: Glyphs.chevronLeft
            label: "previous month"
            onClicked: root.offset--
        },
        HeaderButton {
            objectName: "next"
            glyph: Glyphs.chevronRight
            label: "next month"
            onClicked: root.offset++
        }
    ]

    Grid {
        id: grid

        anchors.fill: parent
        columns: 7

        Repeater {
            model: Calendar.weekdays(root.firstDay)

            Caption {
                required property int modelData

                width: root.cellWidth
                height: root.cellHeight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: Format.weekday(modelData)
            }
        }

        Repeater {
            objectName: "days"
            model: Calendar.weeks(root.first, root.firstDay)

            Item {
                id: day

                required property var modelData

                readonly property bool isToday: Calendar.sameDay(day.modelData, root.today)
                // False for the days either side that fill the first and
                // last weeks.
                readonly property bool inMonth: day.modelData.getMonth() === root.first.getMonth()

                function ink(): color {
                    if (day.isToday)
                        return Colors.activeText;
                    return day.inMonth ? Colors.text : Colors.textFaint;
                }

                width: root.cellWidth
                height: root.cellHeight

                Surface {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 4
                    height: width
                    radius: Rounding.small
                    restColor: "transparent"
                    active: day.isToday
                }

                Label {
                    anchors.centerIn: parent
                    text: day.modelData.getDate()
                    color: day.ink()
                    font.weight: day.isToday ? Font.DemiBold : Font.Normal
                }
            }
        }
    }
}
