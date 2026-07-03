import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets

Variants {
    id: root

    // Panels owned by shell.qml, shared by all screens' bars.
    required property var controlCenter
    required property var notificationHistory
    required property var sessionMenu

    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        anchors {
            top: true
            left: true
            bottom: true
        }

        implicitWidth: 28
        color: Theme.background

        PwObjectTracker {
            objects: [Pipewire.defaultAudioSink]
        }

        ColumnLayout {
            anchors.fill: parent

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 6
                spacing: 2

                Workspaces {
                    output: window.screen.name
                }
            }

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 6
                spacing: 4

                Tray {}

                BarIcon {
                    Layout.fillWidth: true
                    visible: Niri.kbLayout !== ""
                    glyph: Niri.kbLayout
                    size: 10
                    color: Niri.kbLayoutIdx === 0 ? Theme.muted : Theme.warning
                }

                BarIcon {
                    Layout.fillWidth: true
                    glyph: Pipewire.defaultAudioSink?.audio.muted ? "󰖁" : "󰕾"
                    color: Pipewire.defaultAudioSink?.audio.muted ? Theme.muted : Theme.foreground
                    onClicked: root.controlCenter.toggle()
                }

                BarIcon {
                    Layout.fillWidth: true
                    glyph: Network.statusIcon
                    color: Network.wifiConnected || Network.ethernetConnected
                        ? Theme.foreground
                        : Theme.muted
                    onClicked: root.controlCenter.toggle()
                }

                BarIcon {
                    Layout.fillWidth: true
                    visible: Bluetooth.defaultAdapter !== null
                    glyph: {
                        const adapter = Bluetooth.defaultAdapter;
                        if (!adapter || !adapter.enabled)
                            return "󰂲";
                        const connected = [...Bluetooth.devices.values].some(d => d.connected);
                        return connected ? "󰂱" : "󰂯";
                    }
                    color: Bluetooth.defaultAdapter?.enabled ? Theme.primary : Theme.muted
                    onClicked: root.controlCenter.toggle()
                }

                BarIcon {
                    Layout.fillWidth: true
                    glyph: Notifs.history.length > 0 ? "󰂚" : "󰂜"
                    color: Notifs.history.length > 0 ? Theme.foreground : Theme.muted
                    onClicked: root.notificationHistory.toggle()
                }

                Battery {}

                Clock {}

                BarIcon {
                    Layout.fillWidth: true
                    glyph: "󰐥"
                    color: Theme.danger
                    onClicked: root.sessionMenu.toggle()
                }
            }
        }
    }
}
