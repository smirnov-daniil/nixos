import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.Common
import qs.Widgets

BarIcon {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property int percent: Math.round(device.percentage * 100)
    readonly property bool charging: device.state === UPowerDeviceState.Charging
        || device.state === UPowerDeviceState.FullyCharged

    visible: device.ready && device.isLaptopBattery

    Layout.fillWidth: true

    glyph: {
        if (charging)
            return "󰂄";
        if (percent >= 90)
            return "󰁹";
        if (percent >= 70)
            return "󰂀";
        if (percent >= 50)
            return "󰁾";
        if (percent >= 30)
            return "󰁼";
        if (percent >= 15)
            return "󰁻";
        return "󰁺";
    }
    color: {
        if (charging)
            return Theme.success;
        if (percent <= 15)
            return Theme.danger;
        if (percent <= 30)
            return Theme.warning;
        return Theme.foreground;
    }
    label: root.percent + "%"
}
