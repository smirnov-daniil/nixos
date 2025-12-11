import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Battery
Item {
    // System info properties
    property int batteryCapacity: 0

    Layout.fillWidth: true
    Layout.preferredHeight: width
    Layout.alignment: Qt.AlignCenter

    Process {
        id: batteryProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 0"]
        stdout: SplitParser {
            onRead: data => batteryCapacity = parseInt(data) || 0
        }
        Component.onCompleted: running = true
    }

    // Slow timer for system stats
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            batteryProc.running = true
        }
    }

    Text {
        text: batteryCapacity
        color: Theme.base0D
        font.pixelSize: 10
        font.family: Theme.fontFamily
        font.bold: true
        anchors.centerIn: parent
    }

    Text {
        text: "B"
        color: Theme.base0D
        font.pixelSize: 10
        font.family: Theme.fontFamily
        anchors {
            top: parent.bottom
            topMargin: -2
            horizontalCenter: parent.horizontalCenter
        }
    }
}
