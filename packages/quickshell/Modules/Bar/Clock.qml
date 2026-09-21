import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common

// Stacked HH / mm, with the date below. Click opens the calendar.
Item {
    id: root

    signal clicked

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: column
        width: parent.width
        spacing: 0

        Text {
            text: Qt.formatDateTime(clock.date, "HH")
            color: Theme.foreground
            font.pixelSize: 13
            font.family: Theme.fontFamily
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: Qt.formatDateTime(clock.date, "mm")
            color: Theme.foreground
            font.pixelSize: 13
            font.family: Theme.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Separates the time from the date, which otherwise read as one number.
        Rectangle {
            width: 12
            height: 1
            color: Theme.highlight
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: Qt.formatDateTime(clock.date, "dd")
            color: Theme.foreground
            font.pixelSize: 11
            font.family: Theme.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: Qt.formatDateTime(clock.date, "MMM")
            // base04 rather than the muted base03: the month is small enough
            // that the dimmer shade was unreadable against the bar.
            color: Theme.base04
            font.pixelSize: 9
            font.family: Theme.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
