import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.Common
import qs.Services
import qs.Widgets

// Wifi / bluetooth / audio / system in one panel next to the bar, split into
// tabs. The bar's QuickSettings flyout opens it straight on a tab; the strip
// along the top switches between them once it is open.
PopupPanel {
    id: root

    // Fixed: every tab is the same size, so nothing shifts when switching.
    panelHeight: 680
    panelWidth: 360

    // PopupPanel insets its content by 14px a side; grid cells divide what is
    // left so tiles line up across tabs.
    readonly property int contentWidth: panelWidth - 28
    readonly property int halfWidth: (contentWidth - 8) / 2
    readonly property int thirdWidth: (contentWidth - 12) / 3
    readonly property int quarterWidth: (contentWidth - 18) / 4
    exclusiveKeyboard: true

    // "network" | "bluetooth" | "audio" | "system"
    property string tab: "network"

    function openTab(name) {
        tab = name;
        shown = true;
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var battery: UPower.displayDevice
    readonly property var audioInputs: [...Pipewire.nodes.values].filter(node => !node.isSink && !node.isStream && node.audio !== null)
    readonly property var audioStreams: [...Pipewire.nodes.values].filter(node => node.isStream && node.audio !== null)

    property int maxBrightness: 1
    property int currentBrightness: 0
    property string pendingSsid: ""

    // Scanning is per-tab: no bluetooth discovery while the audio tab is up.
    function syncScans() {
        if (shown && tab === "network") {
            Network.refresh();
            Network.scan();
        }
        if (adapter && adapter.enabled)
            adapter.discovering = shown && tab === "bluetooth";
    }

    // A network can look known (a NetworkManager profile exists) and still have
    // no usable secret, which nmcli only discovers on the failed attempt.
    Connections {
        target: Network
        function onSecretsRequired(ssid) {
            root.openTab("network");
            root.pendingSsid = ssid;
            wifiPassword.text = "";
            Qt.callLater(() => wifiPassword.forceActiveFocus());
        }
    }

    onShownChanged: {
        if (shown)
            brightnessRead.running = true;
        else
            pendingSsid = "";
        syncScans();
    }

    onTabChanged: {
        pendingSsid = "";
        flick.contentY = 0;
        syncScans();
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

    // Deliberately not a chip. An active ToggleChip is a solid accent block
    // with inverted text; a selected tab is an unfilled cell marked by a bar
    // on the edge facing its content, lettered in primary rather than accent.
    // The two states must not be mistakable for each other.
    component TabPill: Item {
        id: pill

        required property string glyph
        required property string tabName
        required property string label

        readonly property bool current: root.tab === tabName

        width: root.quarterWidth
        height: 34

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: pill.current
                ? Theme.surface
                : (pillArea.containsMouse ? Theme.highlight : "transparent")
        }

        // The strip sits at the bottom of the panel, so the marker goes on the
        // top edge, pointing at the content the tab belongs to.
        Rectangle {
            visible: pill.current
            width: parent.width - 18
            height: 2
            radius: 1
            color: Theme.primary
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
        }

        Row {
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: pill.glyph
                color: pill.current ? Theme.primary : Theme.muted
                font.pixelSize: 13
                font.family: Theme.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: pill.label
                color: pill.current ? Theme.primary : Theme.muted
                font.pixelSize: 10
                font.family: Theme.fontFamily
                font.bold: pill.current
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.tab = pill.tabName
        }
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
        property int glyphSize: 12
        property int textSize: 10
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
                font.pixelSize: miniButton.glyphSize
                font.family: Theme.fontFamily
            }

            Text {
                text: miniButton.text
                color: miniButton.active ? Theme.background : Theme.foreground
                font.pixelSize: miniButton.textSize
                font.family: Theme.fontFamily
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: miniButton.clicked()
        }
    }

    Row {
        id: tabs

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        spacing: 6

        TabPill {
            glyph: Network.statusIcon
            tabName: "network"
            label: "Net"
        }

        TabPill {
            glyph: root.adapter?.enabled ? "󰂯" : "󰂲"
            tabName: "bluetooth"
            label: "BT"
        }

        TabPill {
            glyph: root.sink?.audio.muted ? "󰖁" : "󰕾"
            tabName: "audio"
            label: "Audio"
        }

        TabPill {
            glyph: "󱐋"
            tabName: "system"
            label: "System"
        }
    }

    Flickable {
        id: flick

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: tabs.top
            bottomMargin: 10
        }
        clip: true
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: 8

            // ---------------------------------------------------------- network

            Column {
                visible: root.tab === "network"
                width: parent.width
                spacing: 8

                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 8

                    ToggleChip {
                        width: root.halfWidth
                        glyph: Network.statusIcon
                        text: Network.wifiEnabled ? (Network.ssid || "Wifi") : "Wifi off"
                        active: Network.wifiEnabled
                        onToggled: Network.toggleWifi()
                    }

                    ToggleChip {
                        width: root.halfWidth
                        glyph: "󰀝"
                        text: "Airplane"
                        active: !Network.networkingEnabled
                        onToggled: {
                            Network.toggleNetworking();
                            if (root.adapter && !Network.networkingEnabled)
                                root.adapter.enabled = false;
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
            }

            // -------------------------------------------------------- bluetooth

            Column {
                visible: root.tab === "bluetooth"
                width: parent.width
                spacing: 8

                ToggleChip {
                    width: root.halfWidth
                    glyph: root.adapter?.enabled ? "󰂯" : "󰂲"
                    text: root.adapter?.enabled ? "Bluetooth on" : "Bluetooth off"
                    active: root.adapter?.enabled ?? false
                    onToggled: {
                        if (!root.adapter)
                            return;
                        root.adapter.enabled = !root.adapter.enabled;
                        root.syncScans();
                    }
                }

                SectionLabel {
                    visible: root.adapter?.enabled ?? false
                    text: root.adapter?.discovering ? "DEVICES · scanning…" : "DEVICES · right-click to forget"
                }

                ListView {
                    width: parent.width
                    height: 260
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
            }

            // ------------------------------------------------------------ audio

            Column {
                visible: root.tab === "audio"
                width: parent.width
                spacing: 8

                SliderRow {
                    width: parent.width
                    glyph: root.sink?.audio.muted ? "󰖁" : "󰕾"
                    value: root.sink?.audio.volume ?? 0
                    onMoved: value => {
                        if (root.sink)
                            root.sink.audio.volume = value;
                    }
                }

                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 8

                    ToggleChip {
                        width: root.halfWidth
                        glyph: root.sink?.audio.muted ? "󰖁" : "󰕾"
                        text: root.sink?.audio.muted ? "Unmute" : "Mute"
                        active: !(root.sink?.audio.muted ?? false)
                        onToggled: {
                            if (root.sink)
                                root.sink.audio.muted = !root.sink.audio.muted;
                        }
                    }

                    ToggleChip {
                        width: root.halfWidth
                        glyph: root.source?.audio.muted ? "󰍭" : "󰍬"
                        text: "Mic"
                        active: !(root.source?.audio.muted ?? true)
                        onToggled: {
                            if (root.source)
                                root.source.audio.muted = !root.source.audio.muted;
                        }
                    }
                }

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

                SectionLabel {
                    text: "OUTPUT"
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
                    text: "INPUT"
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
                    text: "APPLICATIONS"
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
            }

            // ----------------------------------------------------------- system

            Column {
                visible: root.tab === "system"
                width: parent.width
                spacing: 8

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
                    visible: root.battery.ready && root.battery.isLaptopBattery
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

                // A three-way choice, so its own row of equal thirds rather
                // than sharing the toggles' two-column grid.
                Grid {
                    width: parent.width
                    columns: 3
                    spacing: 6

                    Repeater {
                        model: [
                            {label: "Saver", glyph: "󰌪", value: PowerProfile.PowerSaver},
                            {label: "Balanced", glyph: "󰾅", value: PowerProfile.Balanced},
                            {label: "Performance", glyph: "󰓅", value: PowerProfile.Performance, hidden: !PowerProfiles.hasPerformanceProfile}
                        ]

                        MiniButton {
                            required property var modelData
                            visible: !modelData.hidden
                            width: root.thirdWidth
                            height: 34
                            glyph: modelData.glyph
                            text: modelData.label
                            active: PowerProfiles.profile === modelData.value
                            onClicked: PowerProfiles.profile = modelData.value
                        }
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
                    text: "TOGGLES & CAPTURE"
                }

                // Uniform tiles on a two-column grid. The capture actions stay
                // MiniButtons (they click, they don't toggle) but are sized and
                // lettered to match, so the block reads as one field.
                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 8

                    ToggleChip {
                        width: root.halfWidth
                        glyph: "󰅶"
                        text: "Keep awake"
                        active: SystemActions.idleInhibited
                        onToggled: SystemActions.idleInhibited = !SystemActions.idleInhibited
                    }

                    ToggleChip {
                        width: root.halfWidth
                        glyph: "󰖔"
                        text: "Night light"
                        active: SystemActions.nightLight
                        onToggled: SystemActions.nightLight = !SystemActions.nightLight
                    }

                    ToggleChip {
                        width: root.halfWidth
                        glyph: SystemActions.recording ? "󰑊" : "󰻃"
                        text: SystemActions.recording ? "Stop record" : "Record"
                        active: SystemActions.recording
                        onToggled: SystemActions.toggleRecording()
                    }

                    MiniButton {
                        width: root.halfWidth
                        height: 40
                        glyphSize: 15
                        textSize: 12
                        glyph: "󰹑"
                        text: "Full screen"
                        onClicked: SystemActions.screenshotScreen()
                    }

                    MiniButton {
                        width: root.halfWidth
                        height: 40
                        glyphSize: 15
                        textSize: 12
                        glyph: "󰩭"
                        text: "Region"
                        onClicked: SystemActions.screenshotRegion()
                    }
                }
            }

            Item {
                width: 1
                height: 2
            }
        }
    }
}
