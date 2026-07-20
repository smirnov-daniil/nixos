import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Low-battery warnings at 15% (normal) and 5% (critical). Instantiated once
// by shell.qml — not per-screen — so each threshold fires a single popup.
// notify-send loops back through this shell's own NotificationServer.
Scope {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property int percent: Math.round(device.percentage * 100)
    readonly property bool discharging: device.state === UPowerDeviceState.Discharging

    property int warnedAt: 100

    function check() {
        if (!device.ready || !device.isLaptopBattery)
            return;
        if (!discharging) {
            warnedAt = 100;
            return;
        }
        if (percent <= 5 && warnedAt > 5) {
            warnedAt = 5;
            notify("critical", "Battery critical", percent + "% remaining, plug in now");
        } else if (percent <= 15 && warnedAt > 15) {
            warnedAt = 15;
            notify("normal", "Battery low", percent + "% remaining");
        }
    }

    function notify(urgency, summary, body) {
        Quickshell.execDetached(["notify-send", "-a", "power", "-u", urgency, summary, body]);
    }

    onPercentChanged: check()
    onDischargingChanged: check()
}
