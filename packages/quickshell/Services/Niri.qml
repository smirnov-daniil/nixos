pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// niri state via `niri msg --json event-stream`. The stream sends full
// state (WorkspacesChanged, KeyboardLayoutsChanged, ...) on connect, so no
// one-shot queries are needed. niri drops clients that read too slowly, so
// the process auto-restarts and every reconnect is a full resync.
Singleton {
    id: root

    // Workspace objects as sent by niri: id, idx, name, output,
    // is_active, is_focused, is_urgent, active_window_id.
    property var workspaces: []
    property var kbLayoutNames: []
    property int kbLayoutIdx: 0
    property bool overviewOpen: false

    readonly property string kbLayout: {
        const name = kbLayoutNames[kbLayoutIdx] ?? "";
        return name.slice(0, 2).toUpperCase();
    }

    readonly property var focusedWorkspace: workspaces.find(ws => ws.is_focused) ?? null

    readonly property var focusedScreen: {
        const output = focusedWorkspace?.output;
        const screens = Quickshell.screens;
        return screens.find(s => s.name === output) ?? screens[0] ?? null;
    }

    function focusWorkspace(ws) {
        if (ws.name !== null && ws.name !== "") {
            // Named references are stable across outputs.
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", ws.name]);
        } else {
            // Index references resolve against the *focused* monitor, so
            // focus this workspace's monitor first.
            Quickshell.execDetached(["sh", "-c",
                "niri msg action focus-monitor " + ws.output
                + " && niri msg action focus-workspace " + ws.idx]);
        }
    }

    function workspacesOn(output) {
        return workspaces
            .filter(ws => ws.output === output)
            .sort((a, b) => a.idx - b.idx);
    }

    function handleEvent(line) {
        let event;
        try {
            event = JSON.parse(line);
        } catch (e) {
            return;
        }
        const type = Object.keys(event)[0];
        const data = event[type];

        switch (type) {
        case "WorkspacesChanged":
            workspaces = data.workspaces;
            break;
        case "WorkspaceActivated": {
            const activated = workspaces.find(ws => ws.id === data.id);
            if (!activated)
                break;
            workspaces = workspaces.map(ws => {
                const copy = Object.assign({}, ws);
                if (ws.output === activated.output)
                    copy.is_active = ws.id === data.id;
                if (data.focused)
                    copy.is_focused = ws.id === data.id;
                return copy;
            });
            break;
        }
        case "WorkspaceActiveWindowChanged":
            workspaces = workspaces.map(ws => ws.id === data.workspace_id
                ? Object.assign({}, ws, {active_window_id: data.active_window_id})
                : ws);
            break;
        case "WorkspaceUrgencyChanged":
            workspaces = workspaces.map(ws => ws.id === data.id
                ? Object.assign({}, ws, {is_urgent: data.urgent})
                : ws);
            break;
        case "KeyboardLayoutsChanged":
            kbLayoutNames = data.keyboard_layouts.names;
            kbLayoutIdx = data.keyboard_layouts.current_idx;
            break;
        case "KeyboardLayoutSwitched":
            kbLayoutIdx = data.idx;
            break;
        case "OverviewOpenedOrClosed":
            overviewOpen = data.is_open;
            break;
        }
    }

    Process {
        id: stream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: data => root.handleEvent(data)
        }
        onRunningChanged: {
            if (!running)
                restartTimer.start();
        }
    }

    Timer {
        id: restartTimer
        interval: 1500
        onTriggered: stream.running = true
    }
}
