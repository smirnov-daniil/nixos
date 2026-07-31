import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.Common
import qs.Services
import qs.Widgets

// Wifi / bluetooth / audio / brightness in one panel next to the bar.
PopupPanel {
    id: root

    panelWidth: 360
    panelHeight: 680
    exclusiveKeyboard: true

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var battery: UPower.displayDevice
    readonly property var audioInputs: [...Pipewire.nodes.values].filter(node => !node.isSink && !node.isStream && node.audio !== null)
    readonly property var audioStreams: [...Pipewire.nodes.values].filter(node => node.isStream && node.audio !== null)

    property int maxBrightness: 1
    property int currentBrightness: 0
    property string pendingSsid: ""

    // A network can look known (a NetworkManager profile exists) and still have
    // no usable secret, which nmcli only discovers on the failed attempt.
    Connections {
        target: Network
        function onSecretsRequired(ssid) {
            root.pendingSsid = ssid;
            wifiPassword.text = "";
            Qt.callLater(() => wifiPassword.forceActiveFocus());
        }
    }

    onShownChanged: {
        if (shown) {
            Network.refresh();
            Network.scan();
            brightnessRead.running = true;
        } else {
            pendingSsid = "";
        }
        if (adapter && adapter.enabled)
            adapter.discovering = shown;
    }

    PwObjectTracker {
        objects: [...Pipewire.nodes.values]
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

    function duration(seconds) {
        if (!Number.isFinite(seconds) || seconds <= 0)
            return "—";
        const minutes = Math.round(seconds / 60);
        return Math.floor(minutes / 60) + "h " + String(minutes % 60).padStart(2, "0") + "m";
    }

    component SectionLabel: Text {
        color: Theme.muted
        font.pixelSize: 10
        font.family: Theme.fontFamily
        font.bold: true
    }

    component ToggleChip: Rectangle {
        id: toggleChip

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
                text: toggleChip.glyph
                color: toggleChip.active ? Theme.background : Theme.foreground
                font.pixelSize: 15
                font.family: Theme.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: toggleChip.text
                color: toggleChip.active ? Theme.background : Theme.foreground
                font.pixelSize: 12
                font.family: Theme.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: toggleChip.toggled()
        }
    }

    component MiniButton: Rectangle {
        id: miniButton

        property string glyph: ""
        property string text: ""
        property bool active: false
        signal clicked

        width: 100
        height: 30
        radius: 8
        color: active ? Theme.accent : Theme.surface

        Row {
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: miniButton.glyph
                color: miniButton.active ? Theme.background : Theme.foreground
                font.pixelSize: 12
                font.family: Theme.fontFamily
            }

            Text {
                text: miniButton.text
                color: miniButton.active ? Theme.background : Theme.foreground
                font.pixelSize: 10
                font.family: Theme.fontFamily
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: miniButton.clicked()
        }
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: 8

            SectionLabel {
                visible: Media.available
                text: "NOW PLAYING"
            }

            Rectangle {
                visible: Media.available
                width: parent.width
                height: 118
                radius: 10
                color: Theme.surface

                Image {
                    id: albumArt
                    width: 76
                    height: 76
                    anchors {
                        left: parent.left
                        leftMargin: 10
                        top: parent.top
                        topMargin: 10
                    }
                    source: Media.activePlayer?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Column {
                    anchors {
                        left: albumArt.right
                        leftMargin: 10
                        right: parent.right
                        rightMargin: 10
                        top: parent.top
                        topMargin: 10
                    }
                    spacing: 2

                    Text {
                        width: parent.width
                        text: Media.activePlayer?.trackTitle || Media.activePlayer?.identity || "Unknown track"
                        color: Theme.foreground
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: Media.activePlayer?.trackArtist || Media.activePlayer?.trackAlbum || ""
                        color: Theme.muted
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                        elide: Text.ElideRight
                    }

                    Row {
                        spacing: 14

                        Text {
                            text: "󰒮"
                            color: Media.activePlayer?.canGoPrevious ? Theme.foreground : Theme.muted
                            font.pixelSize: 17
                            font.family: Theme.fontFamily
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                onClicked: Media.activePlayer?.previous()
                            }
                        }

                        Text {
                            text: Media.activePlayer?.isPlaying ? "󰏤" : "󰐊"
                            color: Theme.accent
                            font.pixelSize: 17
                            font.family: Theme.fontFamily
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                onClicked: Media.activePlayer?.togglePlaying()
                            }
                        }

                        Text {
                            text: "󰒭"
                            color: Media.activePlayer?.canGoNext ? Theme.foreground : Theme.muted
                            font.pixelSize: 17
                            font.family: Theme.fontFamily
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                onClicked: Media.activePlayer?.next()
                            }
                        }

                        Text {
                            visible: Media.activePlayer?.shuffleSupported ?? false
                            text: "󰒟"
                            color: Media.activePlayer?.shuffle ? Theme.accent : Theme.muted
                            font.pixelSize: 15
                            font.family: Theme.fontFamily
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                onClicked: Media.activePlayer.shuffle = !Media.activePlayer.shuffle
                            }
                        }
                    }
                }

                SliderRow {
                    width: parent.width - 20
                    height: 26
                    anchors {
                        left: parent.left
                        leftMargin: 10
                        bottom: parent.bottom
                        bottomMargin: 2
                    }
                    glyph: ""
                    value: Media.activePlayer?.length > 0 ? Media.activePlayer.position / Media.activePlayer.length : 0
                    onMoved: value => {
                        if (Media.activePlayer?.canSeek)
                            Media.activePlayer.position = value * Media.activePlayer.length;
                    }
                }
            }

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
                    if (!root.adapter)
                        return;
                    root.adapter.enabled = !root.adapter.enabled;
                    if (root.adapter.enabled)
                        root.adapter.discovering = true;
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
                        text: "󰌾"
                        color: Theme.muted
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (modelData.inUse)
                            return;
                        if (modelData.secured && !modelData.known) {
                            root.pendingSsid = modelData.ssid;
                            wifiPassword.text = "";
                            Qt.callLater(() => wifiPassword.forceActiveFocus());
                        } else {
                            Network.connect(modelData.ssid, "");
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: root.pendingSsid !== ""
            width: parent.width
            height: 38
            radius: 8
            color: Theme.surface

            TextInput {
                id: wifiPassword
                anchors {
                    left: parent.left
                    right: connectWifi.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 10
                    rightMargin: 8
                }
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Theme.foreground
                font.pixelSize: 11
                font.family: Theme.fontFamily
                Keys.onReturnPressed: connectWifi.clicked()
                Keys.onEscapePressed: root.pendingSsid = ""
            }

            MiniButton {
                id: connectWifi
                width: 78
                height: 28
                text: Network.connecting ? "…" : "Connect"
                anchors {
                    right: parent.right
                    rightMargin: 5
                    verticalCenter: parent.verticalCenter
                }
                onClicked: {
                    Network.connect(root.pendingSsid, wifiPassword.text);
                    root.pendingSsid = "";
                }
            }
        }

        Text {
            visible: Network.lastError !== ""
            width: parent.width
            text: Network.lastError
            color: Theme.danger
            font.pixelSize: 9
            font.family: Theme.fontFamily
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        SectionLabel {
            visible: Network.vpnConnections.length > 0 || Browsec.available
            text: "VPN"
        }

        Flow {
            visible: Network.vpnConnections.length > 0 || Browsec.available
            width: parent.width
            spacing: 6

            Repeater {
                model: Network.vpnConnections

                MiniButton {
                    required property string modelData
                    width: Math.min(150, Math.max(90, vpnName.implicitWidth + 30))
                    glyph: "󰦝"
                    text: modelData
                    active: Network.activeVpns.includes(modelData)
                    onClicked: Network.toggleVpn(modelData)

                    Text {
                        id: vpnName
                        visible: false
                        text: parent.modelData
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                    }
                }
            }

            // Not a NetworkManager profile (see Services/Browsec.qml), so it
            // sits beside the nmcli-driven entries rather than in their model.
            MiniButton {
                visible: Browsec.available
                width: Math.min(150, Math.max(90, browsecName.implicitWidth + 30))
                glyph: "󰦝"
                text: Browsec.name
                active: Browsec.active
                onClicked: Browsec.toggle()

                Text {
                    id: browsecName
                    visible: false
                    text: Browsec.name
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                }
            }
        }

        SectionLabel {
            visible: root.adapter?.enabled ?? false
            text: root.adapter?.discovering ? "BLUETOOTH · scanning…" : "BLUETOOTH · right-click to forget"
        }

        ListView {
            width: parent.width
            height: 90
            clip: true
            visible: root.adapter?.enabled ?? false
            // ObjectModel directly: valuesChanged fires only on insert/remove,
            // a filtered JS snapshot would go stale on pair/connect changes.
            model: Bluetooth.devices

            delegate: Item {
                id: deviceRow

                required property BluetoothDevice modelData

                readonly property bool relevant: modelData.name !== ""
                    && (modelData.connected || modelData.paired || modelData.bonded
                        || (root.adapter?.discovering ?? false))
                readonly property bool busy: modelData.pairing
                    || modelData.state === BluetoothDeviceState.Connecting
                    || modelData.state === BluetoothDeviceState.Disconnecting

                visible: relevant
                width: parent ? parent.width : 0
                height: relevant ? 26 : 0

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: deviceRow.modelData.connected ? "󰂱" : "󰂯"
                        color: deviceRow.modelData.connected ? Theme.primary : Theme.muted
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                    }

                    Text {
                        text: deviceRow.modelData.name
                        color: deviceRow.modelData.connected ? Theme.foreground : Theme.muted
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                    }

                    Text {
                        visible: deviceRow.busy || deviceRow.modelData.batteryAvailable
                        text: {
                            if (deviceRow.modelData.pairing)
                                return "pairing…";
                            if (deviceRow.busy)
                                return "…";
                            return Math.round(deviceRow.modelData.battery * 100) + "%";
                        }
                        color: Theme.muted
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                    }

                    Text {
                        visible: !deviceRow.modelData.paired && !deviceRow.modelData.bonded
                            && !deviceRow.modelData.connected && !deviceRow.busy
                        text: "new"
                        color: Theme.warning
                        font.pixelSize: 9
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        const device = deviceRow.modelData;
                        if (deviceRow.busy)
                            return;
                        if (mouse.button === Qt.RightButton) {
                            device.forget();
                        } else if (device.connected) {
                            device.disconnect();
                        } else if (device.paired || device.bonded) {
                            device.connect();
                        } else {
                            device.trusted = true;
                            device.pair();
                        }
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

        SectionLabel {
            visible: root.audioInputs.length > 0
            text: "AUDIO INPUT"
        }

        ListView {
            width: parent.width
            height: Math.min(root.audioInputs.length * 24, 72)
            clip: true
            visible: root.audioInputs.length > 0
            model: root.audioInputs

            delegate: Item {
                id: inputRow

                required property var modelData
                readonly property bool isDefault: modelData === Pipewire.defaultAudioSource

                width: parent ? parent.width : 0
                height: 24

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: inputRow.isDefault ? "󰄬" : " "
                        color: Theme.success
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                    }

                    Text {
                        width: 280
                        text: inputRow.modelData.description || inputRow.modelData.name
                        color: inputRow.isDefault ? Theme.foreground : Theme.muted
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Pipewire.preferredDefaultAudioSource = inputRow.modelData
                }
            }
        }

        SectionLabel {
            visible: root.audioStreams.length > 0
            text: "APPLICATION AUDIO"
        }

        ListView {
            width: parent.width
            height: Math.min(root.audioStreams.length * 48, 144)
            clip: true
            spacing: 2
            visible: root.audioStreams.length > 0
            model: root.audioStreams

            delegate: Item {
                id: streamRow
                required property var modelData

                width: parent ? parent.width : 0
                height: 46

                Text {
                    width: parent.width
                    text: modelData.properties["application.name"] || modelData.properties["media.name"] || modelData.description || modelData.name
                    color: Theme.foreground
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                }

                SliderRow {
                    width: parent.width
                    anchors.bottom: parent.bottom
                    glyph: streamRow.modelData.audio.muted ? "󰖁" : (streamRow.modelData.isSink ? "󰍬" : "󰕾")
                    value: streamRow.modelData.audio.volume
                    onMoved: value => streamRow.modelData.audio.volume = value

                    MouseArea {
                        width: 24
                        height: parent.height
                        onClicked: streamRow.modelData.audio.muted = !streamRow.modelData.audio.muted
                    }
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

        SectionLabel {
            text: "POWER"
        }

        Rectangle {
            visible: root.battery.ready && root.battery.isLaptopBattery
            width: parent.width
            height: 54
            radius: 8
            color: Theme.surface

            Row {
                anchors {
                    fill: parent
                    margins: 9
                }
                spacing: 14

                Text {
                    text: Math.round(root.battery.percentage * 100) + "%"
                    color: Theme.foreground
                    font.pixelSize: 15
                    font.family: Theme.fontFamily
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: root.battery.state === UPowerDeviceState.Charging
                            ? root.duration(root.battery.timeToFull) + " to full"
                            : root.duration(root.battery.timeToEmpty) + " remaining"
                        color: Theme.foreground
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                    }

                    Text {
                        text: (root.battery.healthSupported ? Math.round(root.battery.healthPercentage * 100) + "% health · " : "")
                            + root.battery.changeRate.toFixed(1) + " W"
                        color: Theme.muted
                        font.pixelSize: 9
                        font.family: Theme.fontFamily
                    }
                }
            }
        }

        Row {
            spacing: 6

            Repeater {
                model: [
                    {label: "Saver", value: PowerProfile.PowerSaver},
                    {label: "Balanced", value: PowerProfile.Balanced},
                    {label: "Performance", value: PowerProfile.Performance, hidden: !PowerProfiles.hasPerformanceProfile}
                ]

                MiniButton {
                    required property var modelData
                    visible: !modelData.hidden
                    width: modelData.hidden ? 0 : 105
                    glyph: modelData.value === PowerProfile.PowerSaver ? "󰌪" : modelData.value === PowerProfile.Performance ? "󰓅" : "󰾅"
                    text: modelData.label
                    active: PowerProfiles.profile === modelData.value
                    onClicked: PowerProfiles.profile = modelData.value
                }
            }
        }

        Row {
            spacing: 12

            ToggleChip {
                glyph: "󰀝"
                text: "Airplane"
                active: !Network.networkingEnabled
                onToggled: {
                    Network.toggleNetworking();
                    if (root.adapter && !Network.networkingEnabled)
                        root.adapter.enabled = false;
                }
            }

            ToggleChip {
                glyph: "󰅶"
                text: "Keep awake"
                active: SystemActions.idleInhibited
                onToggled: SystemActions.idleInhibited = !SystemActions.idleInhibited
            }
        }

        Row {
            spacing: 12

            ToggleChip {
                glyph: "󰖔"
                text: "Night light"
                active: SystemActions.nightLight
                onToggled: SystemActions.nightLight = !SystemActions.nightLight
            }

            ToggleChip {
                glyph: SystemActions.recording ? "󰑊" : "󰻃"
                text: SystemActions.recording ? "Stop record" : "Record"
                active: SystemActions.recording
                onToggled: SystemActions.toggleRecording()
            }
        }

        SliderRow {
            visible: SystemActions.nightLight
            width: parent.width
            glyph: "󰖨"
            fillColor: Theme.warning
            value: (SystemActions.nightTemperature - 2500) / 4000
            onMoved: value => SystemActions.setNightTemperature(2500 + value * 4000)
        }

        SectionLabel {
            text: "CAPTURE"
        }

        Row {
            spacing: 6

            MiniButton {
                width: 150
                glyph: "󰹑"
                text: "Full screen"
                onClicked: SystemActions.screenshotScreen()
            }

            MiniButton {
                width: 150
                glyph: "󰩭"
                text: "Region"
                onClicked: SystemActions.screenshotRegion()
            }
        }

        Item {
            width: 1
            height: 2
        }
        }
    }
}
