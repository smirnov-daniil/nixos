pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool idleInhibited: false
    property bool nightLight: false
    property int nightTemperature: 4000
    property bool recording: false

    function setNightTemperature(value) {
        nightTemperature = Math.max(2500, Math.min(6500, Math.round(value)));
        if (nightLight)
            Quickshell.execDetached(["gammastep", "-O", String(nightTemperature)]);
    }

    function screenshotScreen() {
        Quickshell.execDetached(["sh", "-c", "grim - | wl-copy"]);
    }

    function screenshotRegion() {
        Quickshell.execDetached(["sh", "-c", "grim -g \"$(slurp -w 0)\" - | wl-copy"]);
    }

    function toggleRecording() {
        recording = !recording;
    }

    Process {
        id: idleProc
        command: ["systemd-inhibit", "--what=idle", "--who=Quickshell", "--why=Keep awake", "sleep", "infinity"]
        running: root.idleInhibited
        onExited: root.idleInhibited = false
    }

    Process {
        id: nightProc
        command: ["sh", "-c", "gammastep -O \"$1\"; trap 'gammastep -x' EXIT TERM INT; while :; do sleep 3600; done", "sh", String(root.nightTemperature)]
        running: root.nightLight
        onExited: root.nightLight = false
    }

    Process {
        id: recordProc
        command: ["sh", "-c", "mkdir -p \"$HOME/Videos\"; exec wf-recorder -f \"$HOME/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4\""]
        running: root.recording
        onExited: root.recording = false
    }
}
