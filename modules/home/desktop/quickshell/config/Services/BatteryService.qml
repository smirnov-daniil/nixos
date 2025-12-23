import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property int percentage: 0
    property bool isCharging: false
    property string timeRemaining: ""
    property double watts: 0.0
    property string warningLevel: ""
    property string icon: "battery"

    // Moving these out of "property" declarations 
    // makes them active children of the Service.

    Timer {
        id: timer
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true 
        onTriggered: {
            proc.running = false 
            proc.running = true
        }
    }

    Process {
        id: proc
        command: ["upower", "-b"]
        stdout: StdioCollector {
            onStreamFinished: _parseUpower(this.text)
        }
    }

    function _parseUpower(output) {
        const lines = output.split("\n");
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (line.startsWith("percentage:")) {
                root.percentage = parseInt(line.split(":")[1].trim().replace("%", ""));
            }
            if (line.startsWith("state:")) {
                root.isCharging = (line.split(":")[1].trim() === "charging");
            }
            if (line.startsWith("time to empty:") || line.startsWith("time to full:")) {
                root.timeRemaining = line.split(":")[1].trim();
            }
            if (line.startsWith("energy-rate:")) {
                root.watts = parseFloat(line.split(":")[1].trim().split(" ")[0]);
            }
            if (line.startsWith("warning-level:")) {
                root.warningLevel = line.split(":")[1].trim();
            }
            if (line.startsWith("icon-name:")) {
                let val = line.split(":")[1].trim();
                root.icon = val.split("'")[1];
            }
         }
    }
}
