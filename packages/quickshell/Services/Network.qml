pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wifi/ethernet state via nmcli polling (NetworkManager has no QML API).
Singleton {
    id: root

    property bool networkingEnabled: true
    property bool wifiEnabled: true
    property bool wifiConnected: false
    property bool ethernetConnected: false
    property string ssid: ""
    property int signal: 0
    // [{ssid, signal, secured, inUse, known}] strongest first
    property var networks: []
    property bool scanning: false
    property var _savedNames: []
    property var vpnConnections: []
    property var activeVpns: []
    property string lastError: ""

    readonly property string statusIcon: {
        if (ethernetConnected)
            return "󰈀";
        if (!wifiEnabled)
            return "󰖪";
        if (!wifiConnected)
            return "󰤭";
        if (signal >= 75)
            return "󰤨";
        if (signal >= 50)
            return "󰤥";
        if (signal >= 25)
            return "󰤢";
        return "󰤟";
    }

    function refresh() {
        statusProc.running = true;
        savedProc.running = true;
        vpnProc.running = true;
    }

    function scan() {
        if (scanning)
            return;
        scanning = true;
        scanProc.running = true;
    }

    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]);
        wifiEnabled = !wifiEnabled; // optimistic; poll corrects if needed
        refreshSoon.restart();
    }

    function toggleNetworking() {
        Quickshell.execDetached(["nmcli", "networking", networkingEnabled ? "off" : "on"]);
        networkingEnabled = !networkingEnabled;
        refreshSoon.restart();
    }

    function toggleVpn(name) {
        const active = activeVpns.includes(name);
        Quickshell.execDetached(["nmcli", "connection", active ? "down" : "up", name]);
        refreshSoon.restart();
    }

    property bool connecting: false

    function connect(ssid, password) {
        if (connecting)
            return;
        connecting = true;
        lastError = "";
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid];
        if (password)
            connectProc.command = connectProc.command.concat(["password", password]);
        connectProc.running = true;
    }

    // Splits an nmcli -t line into `count` fields, keeping any extra ':'
    // inside the last field and unescaping it (nmcli -t escapes ':' and
    // '\' in values; SSIDs may contain both).
    function _fields(line, count) {
        const fields = [];
        let field = "";
        let escaped = false;
        for (const character of line) {
            if (escaped) {
                field += character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else if (character === ":" && fields.length < count - 1) {
                fields.push(field);
                field = "";
            } else {
                field += character;
            }
        }
        if (escaped)
            field += "\\";
        fields.push(field);
        return fields;
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshSoon
        interval: 3000
        onTriggered: root.refresh()
    }

    Process {
        id: statusProc
        command: ["sh", "-c", "nmcli networking; nmcli radio wifi; nmcli -t -f TYPE,STATE device; nmcli -t -f IN-USE,SIGNAL,SSID device wifi list --rescan no"]
        environment: ({LC_ALL: "C"})
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l !== "");
                root.networkingEnabled = lines[0]?.trim() === "enabled";
                root.wifiEnabled = lines[1]?.trim() === "enabled";
                let wifiUp = false;
                let ethUp = false;
                let ssid = "";
                let signal = 0;
                for (const line of lines.slice(2)) {
                    // Wifi-list lines start with "*" (in use) or ":" (empty
                    // IN-USE field); everything else is a device line.
                    if (line.includes(":") && !line.startsWith("*") && !line.startsWith(":") && !line.startsWith(" ")) {
                        const [type, state] = root._fields(line, 2);
                        if (type === "wifi" && state === "connected")
                            wifiUp = true;
                        if (type === "ethernet" && state === "connected")
                            ethUp = true;
                    }
                    if (line.startsWith("*")) {
                        const f = root._fields(line, 3);
                        signal = parseInt(f[1]) || 0;
                        ssid = f[2];
                    }
                }
                root.wifiConnected = wifiUp;
                root.ethernetConnected = ethUp;
                root.ssid = wifiUp ? ssid : "";
                root.signal = wifiUp ? signal : 0;
            }
        }
    }

    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        environment: ({LC_ALL: "C"})
        stdout: StdioCollector {
            onStreamFinished: {
                const connections = text.split("\n").filter(line => line !== "").map(line => root._fields(line, 2));
                root._savedNames = connections.map(fields => fields[0]);
                root.vpnConnections = connections
                    .filter(fields => fields[1] === "vpn" || fields[1] === "wireguard")
                    .map(fields => fields[0]);
            }
        }
    }

    Process {
        id: vpnProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        environment: ({LC_ALL: "C"})
        stdout: StdioCollector {
            onStreamFinished: root.activeVpns = text.split("\n")
                .filter(line => line !== "")
                .map(line => root._fields(line, 2))
                .filter(fields => fields[1] === "vpn" || fields[1] === "wireguard")
                .map(fields => fields[0])
        }
    }

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "yes"]
        environment: ({LC_ALL: "C"})
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                for (const line of text.split("\n")) {
                    if (line === "")
                        continue;
                    const f = root._fields(line, 4);
                    const entry = {
                        inUse: f[0] === "*",
                        signal: parseInt(f[1]) || 0,
                        secured: f[2] !== "" && f[2] !== "--",
                        ssid: f[3],
                        known: root._savedNames.includes(f[3])
                    };
                    if (entry.ssid === "")
                        continue;
                    if (!seen[entry.ssid] || seen[entry.ssid].signal < entry.signal)
                        seen[entry.ssid] = entry;
                }
                root.networks = Object.values(seen).sort((a, b) => b.signal - a.signal);
                root.scanning = false;
            }
        }
        onRunningChanged: {
            if (!running)
                root.scanning = false;
        }
    }

    Process {
        id: connectProc
        environment: ({LC_ALL: "C"})
        stderr: StdioCollector {
            onStreamFinished: root.lastError = text.trim()
        }
        onRunningChanged: {
            if (!running) {
                root.connecting = false;
                refreshSoon.restart();
            }
        }
    }
}
