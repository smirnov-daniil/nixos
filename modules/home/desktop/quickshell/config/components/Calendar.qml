import Quickshell
import QtQuick
import QtQuick.Layouts

// Calendar/Time
Item {
    Layout.fillWidth: true
    Layout.preferredHeight: width
    Layout.alignment: Qt.AlignCenter

    Text {
        id: clockHour
        text: Qt.formatDateTime(new Date(), "HH")
        color: Theme.base0C
        font.pixelSize: 10
        font.family: Theme.fontFamily
        font.bold: true
        anchors.centerIn: parent
    }

    Text {
        id: clockDate
        text: Qt.formatDateTime(new Date(), "dd")
        color: Theme.base0C
        font.pixelSize: 10
        font.family: Theme.fontFamily
        anchors {
            top: parent.bottom
            topMargin: -2
            horizontalCenter: parent.horizontalCenter
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockHour.text = Qt.formatDateTime(new Date(), "HH")
            clockDate.text = Qt.formatDateTime(new Date(), "dd")
        }
    }
}
