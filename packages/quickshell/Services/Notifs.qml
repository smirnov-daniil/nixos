pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon: live popups + a plain-data history list.
Singleton {
    id: root

    // Live Notification objects currently shown as popups.
    property var popups: []
    // Plain copies (survive Notification destruction): {appName, appIcon,
    // image, summary, body, urgency, time}
    property var history: []
    property int maxPopups: 5
    property int maxHistory: 50

    function _removePopup(notification) {
        popups = popups.filter(p => p !== notification);
    }

    function clearHistory() {
        history = [];
    }

    function timeoutFor(notification) {
        if (notification.expireTimeout > 0)
            return notification.expireTimeout;
        return notification.urgency === NotificationUrgency.Critical ? 15000 : 6000;
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;
            notification.closed.connect(() => root._removePopup(notification));

            root.history = [{
                appName: notification.appName,
                appIcon: notification.appIcon,
                image: notification.image,
                summary: notification.summary,
                body: notification.body,
                urgency: notification.urgency,
                time: new Date()
            }].concat(root.history).slice(0, root.maxHistory);

            let next = root.popups.concat([notification]);
            while (next.length > root.maxPopups) {
                next[0].dismiss();
                next = next.slice(1);
            }
            root.popups = next;
        }
    }
}
