import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common

// Stacked HH / mm, with day-of-month below.
Column {
    Layout.fillWidth: true
    spacing: 0

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        text: Qt.formatDateTime(clock.date, "HH")
        color: Theme.foreground
        font.pixelSize: 11
        font.family: Theme.fontFamily
        font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
        text: Qt.formatDateTime(clock.date, "mm")
        color: Theme.foreground
        font.pixelSize: 11
        font.family: Theme.fontFamily
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
        text: Qt.formatDateTime(clock.date, "dd")
        color: Theme.muted
        font.pixelSize: 9
        font.family: Theme.fontFamily
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
