pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Browsec sits next to the WireGuard entries in the VPN section, but it is not
// a NetworkManager profile: the tunnel is raised by browbox (sing-box) under
// the Electron app, which owns the account and the server choice. So the state
// is read from the interface the app hardcodes, turning it off stops browbox
// directly, and turning it on can only hand over to the app.
Singleton {
    id: root

    // resources/app.asar: getInboundInterface() { return "utun9" }
    readonly property string interfaceName: "utun9"
    readonly property string name: "Browsec"

    property bool active: false
    // The host may not install browsec at all (nixosModules.browsec is opt-in),
    // so the row only appears when the app is actually on PATH.
    property bool available: false

    function refresh() {
        if (!stateProc.running)
            stateProc.running = true;
    }

    function toggle() {
        if (active)
            Quickshell.execDetached(["pkill", "-INT", "-f", "browbox"]);
        else
            Quickshell.execDetached(["browsec-desktop"]);
        refreshSoon.restart();
    }

    Process {
        id: probeProc
        running: true
        command: ["sh", "-c", "command -v browsec-desktop"]
        stdout: StdioCollector {
            onStreamFinished: root.available = text.trim() !== ""
        }
    }

    Process {
        id: stateProc
        command: ["ip", "-brief", "link", "show", root.interfaceName]
        environment: ({LC_ALL: "C"})
        stdout: StdioCollector {
            // `ip link show <missing>` exits non-zero with empty stdout.
            onStreamFinished: root.active = text.trim() !== ""
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshSoon
        interval: 1500
        onTriggered: root.refresh()
    }
}
