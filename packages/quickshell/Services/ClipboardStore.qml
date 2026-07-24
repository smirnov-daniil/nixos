pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var entries: []
    property bool loading: false

    function refresh() {
        if (listProc.running)
            return;
        loading = true;
        listProc.running = true;
    }

    function copy(id) {
        const value = String(id);
        if (!/^\d+$/.test(value))
            return;
        copyProc.command = ["sh", "-c", "cliphist decode " + value + " | wl-copy"];
        copyProc.running = true;
    }

    function remove(entry) {
        if (deleteProc.running)
            return;
        deleteProc.pending = entry.raw;
        deleteProc.running = true;
    }

    function clear() {
        clearProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(line => line !== "").map(line => {
                    const separator = line.indexOf("\t");
                    return {
                        id: separator === -1 ? line : line.slice(0, separator),
                        preview: separator === -1 ? line : line.slice(separator + 1),
                        raw: line
                    };
                });
                root.loading = false;
            }
        }
        onExited: root.loading = false
    }

    Process {
        id: copyProc
    }

    Process {
        id: deleteProc
        property string pending: ""
        command: ["cliphist", "delete"]
        stdinEnabled: true
        onStarted: write(pending + "\n")
        onExited: root.refresh()
    }

    Process {
        id: clearProc
        command: ["cliphist", "wipe"]
        onExited: root.refresh()
    }
}
