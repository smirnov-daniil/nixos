pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification daemon: live popups + a plain-data history list.
Singleton {
    id: root

    // Live Notification objects currently shown as popups.
    property var popups: []
    // Plain copies (survive Notification destruction): {appName, appIcon,
    // image, summary, body, urgency, time}
    property var history: []
    // DND: suppress popups (critical still shows), keep recording history.
    property bool dnd: false
    property bool scheduledDnd: false
    property int dndStartHour: 22
    property int dndEndHour: 8
    property int maxPopups: 5
    property int maxHistory: 50
    property int clockHour: new Date().getHours()

    readonly property bool effectiveDnd: dnd || (scheduledDnd && (dndStartHour < dndEndHour
        ? clockHour >= dndStartHour && clockHour < dndEndHour
        : clockHour >= dndStartHour || clockHour < dndEndHour))
    readonly property var groupedHistory: {
        const groups = [];
        const indexes = {};
        for (const entry of history) {
            const name = entry.appName || "unknown";
            if (indexes[name] === undefined) {
                indexes[name] = groups.length;
                groups.push({appName: name, entries: []});
            }
            groups[indexes[name]].entries.push(entry);
        }
        return groups;
    }

    function _removePopup(notification) {
        popups = popups.filter(p => p !== notification);
    }

    function toggleDnd() {
        dnd = !dnd;
        persist();
    }

    function toggleScheduledDnd() {
        scheduledDnd = !scheduledDnd;
        persist();
    }

    function clearHistory() {
        for (const entry of history) {
            if (entry.live)
                entry.live.dismiss();
        }
        history = [];
        persist();
    }

    function dismissHistory(key) {
        const entry = history.find(item => item.key === key);
        if (entry?.live)
            entry.live.dismiss();
        history = history.filter(item => item.key !== key);
        persist();
    }

    function _markClosed(key) {
        history = history.map(entry => entry.key === key
            ? Object.assign({}, entry, {live: null})
            : entry);
        persist();
    }

    function persist() {
        const stored = history.map(entry => ({
            key: entry.key,
            appName: entry.appName,
            appIcon: entry.appIcon,
            image: entry.image,
            summary: entry.summary,
            body: entry.body,
            urgency: entry.urgency,
            time: entry.time.toISOString()
        }));
        historyFile.setText(JSON.stringify({
            dnd: dnd,
            scheduledDnd: scheduledDnd,
            dndStartHour: dndStartHour,
            dndEndHour: dndEndHour,
            history: stored
        }));
    }

    function restore(raw) {
        if (!raw)
            return;
        try {
            const state = JSON.parse(raw);
            dnd = state.dnd ?? false;
            scheduledDnd = state.scheduledDnd ?? false;
            dndStartHour = state.dndStartHour ?? 22;
            dndEndHour = state.dndEndHour ?? 8;
            history = (state.history ?? []).map(entry => Object.assign({}, entry, {
                time: new Date(entry.time),
                live: null
            })).slice(0, maxHistory);
        } catch (e) {
            console.error("Notifs: failed to restore history:", e);
        }
    }

    function timeoutFor(notification) {
        if (notification.expireTimeout > 0)
            return notification.expireTimeout;
        return notification.urgency === NotificationUrgency.Critical ? 15000 : 6000;
    }

    NotificationServer {
        id: server

        keepOnReload: false
        persistenceSupported: true
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: notification => {
            notification.tracked = true;
            const key = String(Date.now()) + "-" + String(notification.id);
            notification.closed.connect(() => {
                root._removePopup(notification);
                root._markClosed(key);
            });

            root.history = [{
                key: key,
                appName: notification.appName,
                appIcon: notification.appIcon,
                image: notification.image,
                summary: notification.summary,
                body: notification.body,
                urgency: notification.urgency,
                time: new Date(),
                live: notification
            }].concat(root.history).slice(0, root.maxHistory);
            root.persist();

            if (root.effectiveDnd && notification.urgency !== NotificationUrgency.Critical) {
                // Expire instead of just skipping the popup — a tracked
                // notification nobody dismisses lingers in the server forever.
                notification.expire();
                return;
            }

            let next = root.popups.concat([notification]);
            while (next.length > root.maxPopups) {
                next[0].dismiss();
                next = next.slice(1);
            }
            root.popups = next;
        }
    }

    FileView {
        id: historyFile
        path: Quickshell.stateDir + "/notifications.json"
        preload: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.restore(text())
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.clockHour = new Date().getHours()
    }
}
