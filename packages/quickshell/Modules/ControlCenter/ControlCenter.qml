import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Common
import qs.Services
import qs.Widgets

// Wifi / bluetooth / audio / brightness in one panel next to the bar.
PopupPanel {
    id: root

    panelWidth: 330
    panelHeight: 580

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var adapter: Bluetooth.defaultAdapter

    property int maxBrightness: 1
    property int currentBrightness: 0

    onShownChanged: {
        if (shown) {
            Network.refresh();
            Network.scan();
            brightnessRead.running = true;
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource,
            ...Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)]
    }

    Process {
        id: brightnessRead
        command: ["sh", "-c", "brightnessctl max; brightnessctl get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                root.maxBrightness = Math.max(1, parseInt(lines[0]) || 1);
                root.currentBrightness = parseInt(lines[1]) || 0;
            }
        }
    }

    component SectionLabel: Text {
        color: Theme.muted
        font.pixelSize: 10
        font.family: Theme.fontFamily
        font.bold: true
    }

    component ToggleChip: Rectangle {
        property string glyph: ""
        property string text: ""
        property bool active: false
        signal toggled

        width: 145
        height: 40
        radius: 10
        color: active ? Theme.accent : Theme.surface

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: parent.parent.glyph
                color: parent.parent.active ? Theme.background : Theme.foreground
                font.pixelSize: 15
                font.family: Theme.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: parent.parent.text
                color: parent.parent.active ? Theme.background : Theme.foreground
                font.pixelSize: 12
                font.family: Theme.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.toggled()
        }
    }

    Column {
        anchors.fill: parent
        spacing: 8

        Row {
            spacing: 12

            ToggleChip {
                glyph: Network.statusIcon
                text: Network.wifiEnabled ? (Network.ssid || "Wifi") : "Wifi off"
                active: Network.wifiEnabled
                onToggled: Network.toggleWifi()
            }

            ToggleChip {
                glyph: root.adapter?.enabled ? "󰂯" : "󰂲"
                text: "Bluetooth"
                active: root.adapter?.enabled ?? false
                onToggled: {
                    if (root.adapter)
                        root.adapter.enabled = !root.adapter.enabled;
                }
            }
        }

        SectionLabel {
            text: Network.scanning ? "WIFI · scanning…" : "WIFI"
        }

        ListView {
            width: parent.width
            height: 120
            clip: true
            visible: Network.wifiEnabled
            model: Network.networks

            delegate: Item {
                required property var modelData

                width: parent ? parent.width : 0
                height: 26

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: modelData.signal >= 75 ? "󰤨" : modelData.signal >= 50 ? "󰤥" : modelData.signal >= 25 ? "󰤢" : "󰤟"
                        color: modelData.inUse ? Theme.success : Theme.foreground
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                    }

                    Text {
                        text: modelData.ssid
                        color: modelData.inUse ? Theme.success : Theme.foreground
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                        font.bold: modelData.inUse
                    }

                    Text {
                        visible: modelData.secured
                        text: ""
                        color: Theme.muted
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!modelData.inUse)
                            Network.connect(modelData.ssid);
                    }
                }
            }
        }

        SectionLabel {
            visible: root.adapter?.enabled ?? false
            text: "BLUETOOTH"
        }

        ListView {
            width: parent.width
            height: 90
            clip: true
            visible: root.adapter?.enabled ?? false
            model: [...Bluetooth.devices.values].filter(d => d.paired || d.connected)

            delegate: Item {
                required property var modelData

                width: parent ? parent.width : 0
                height: 26

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: modelData.connected ? "󰂱" : "󰂯"
                        color: modelData.connected ? Theme.primary : Theme.muted
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                    }

                    Text {
                        text: modelData.name
                        color: modelData.connected ? Theme.foreground : Theme.muted
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                    }

                    Text {
                        visible: modelData.batteryAvailable
                        text: Math.round(modelData.battery * 100) + "%"
                        color: Theme.muted
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (modelData.connected)
                            modelData.disconnect();
                        else
                            modelData.connect();
                    }
                }
            }
        }

        SectionLabel {
            text: "AUDIO OUTPUT"
        }

        ListView {
            width: parent.width
            height: 70
            clip: true
            model: [...Pipewire.nodes.values].filter(n => n.isSink && !n.isStream)

            delegate: Item {
                required property var modelData

                readonly property bool isDefault: modelData === Pipewire.defaultAudioSink

                width: parent ? parent.width : 0
                height: 24

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: isDefault ? "󰄬" : " "
                        color: Theme.success
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                    }

                    Text {
                        text: modelData.description || modelData.name
                        color: isDefault ? Theme.foreground : Theme.muted
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                        elide: Text.ElideRight
                        width: 250
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }

        SliderRow {
            width: parent.width
            glyph: root.sink?.audio.muted ? "󰖁" : "󰕾"
            value: root.sink?.audio.volume ?? 0
            onMoved: value => {
                if (root.sink)
                    root.sink.audio.volume = value;
            }
        }

        Row {
            spacing: 12

            ToggleChip {
                glyph: root.sink?.audio.muted ? "󰖁" : "󰕾"
                text: root.sink?.audio.muted ? "Unmute" : "Mute"
                active: !(root.sink?.audio.muted ?? false)
                onToggled: {
                    if (root.sink)
                        root.sink.audio.muted = !root.sink.audio.muted;
                }
            }

            ToggleChip {
                glyph: root.source?.audio.muted ? "󰍭" : "󰍬"
                text: "Mic"
                active: !(root.source?.audio.muted ?? true)
                onToggled: {
                    if (root.source)
                        root.source.audio.muted = !root.source.audio.muted;
                }
            }
        }

        SliderRow {
            width: parent.width
            glyph: "󰃟"
            fillColor: Theme.warning
            value: root.currentBrightness / root.maxBrightness
            onMoved: value => {
                // Floor at 1% — 0% turns the panel completely off.
                const percent = Math.max(1, Math.round(value * 100));
                root.currentBrightness = Math.round(percent / 100 * root.maxBrightness);
                Quickshell.execDetached(["brightnessctl", "set", percent + "%"]);
            }
        }
    }
}
