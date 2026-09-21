import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import qs.Common
import qs.Services
import qs.Widgets

// One bar entry standing in for wifi, bluetooth and audio. Hovering it opens a
// flyout of tab glyphs beside the bar; clicking a glyph opens the control
// centre on that tab. Clicking the entry itself reopens the last tab used.
Item {
    id: root

    required property var controlCenter

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool anyProblem: !Network.networkingEnabled
        || !(Network.wifiConnected || Network.ethernetConnected)

    // Bluetooth.devices only signals insert/remove; bump a revision on
    // per-device connect changes so the glyph binding re-evaluates.
    property int btRev: 0

    Layout.fillWidth: true
    implicitHeight: icon.implicitHeight

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Item {
        visible: false

        Repeater {
            model: Bluetooth.devices

            Item {
                required property BluetoothDevice modelData

                Connections {
                    target: modelData

                    function onConnectedChanged() {
                        root.btRev++;
                    }
                }
            }
        }
    }

    // Same language as the panel's tab strip: the tab standing for the open
    // panel is outlined and marked, never filled with accent — accent means
    // "this toggle is on" everywhere else in the shell.
    component TabButton: Item {
        id: tab

        required property string glyph
        required property string tabName
        property color glyphColor: Theme.foreground

        // Optional: the flyout is built before Bar assigns controlCenter.
        readonly property bool current: (root.controlCenter?.shown ?? false)
            && root.controlCenter?.tab === tabName

        width: 30
        height: 32

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: tab.current
                ? Theme.surface
                : (tabArea.containsMouse ? Theme.highlight : "transparent")
        }

        Rectangle {
            visible: tab.current
            width: parent.width - 12
            height: 2
            radius: 1
            color: Theme.primary
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
        }

        Text {
            anchors.centerIn: parent
            text: tab.glyph
            color: tab.current ? Theme.primary : tab.glyphColor
            font.pixelSize: 15
            font.family: Theme.fontFamily
        }

        MouseArea {
            id: tabArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.controlCenter?.openTab(tab.tabName);
                flyout.forceClose();
            }
        }
    }

    BarIcon {
        id: icon
        anchors.fill: parent
        glyph: "󰒓"
        color: root.anyProblem ? Theme.warning : Theme.foreground
        onClicked: root.controlCenter?.toggle()
    }

    BarFlyout {
        id: flyout
        anchorItem: icon
        anchorHovered: icon.hovered

        Row {
            spacing: 4

            TabButton {
                glyph: Network.statusIcon
                tabName: "network"
                glyphColor: Network.wifiConnected || Network.ethernetConnected
                    ? Theme.foreground
                    : Theme.muted
            }

            TabButton {
                glyph: {
                    void root.btRev;
                    if (!root.adapter || !root.adapter.enabled)
                        return "󰂲";
                    const connected = [...Bluetooth.devices.values].some(d => d.connected);
                    return connected ? "󰂱" : "󰂯";
                }
                tabName: "bluetooth"
                glyphColor: root.adapter?.enabled ? Theme.primary : Theme.muted
            }

            TabButton {
                glyph: Pipewire.defaultAudioSink?.audio.muted ? "󰖁" : "󰕾"
                tabName: "audio"
                glyphColor: Pipewire.defaultAudioSink?.audio.muted ? Theme.muted : Theme.foreground
            }

            TabButton {
                glyph: "󱐋"
                tabName: "system"
            }
        }
    }
}
