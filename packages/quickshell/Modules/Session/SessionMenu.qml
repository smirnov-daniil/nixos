import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services

// Fullscreen session menu: lock / logout / suspend / hibernate / poweroff /
// reboot. Click a tile or press its key.
PanelWindow {
    id: root

    property bool shown: false

    readonly property var actions: [
        {key: "l", label: "Lock", glyph: "󰌾", command: "loginctl lock-session"},
        {key: "e", label: "Logout", glyph: "󰗽", command: "loginctl terminate-user $USER"},
        {key: "u", label: "Suspend", glyph: "󰤄", command: "systemctl suspend"},
        {key: "h", label: "Hibernate", glyph: "󰋊", command: "systemctl hibernate"},
        {key: "s", label: "Shutdown", glyph: "󰐥", command: "systemctl poweroff"},
        {key: "r", label: "Reboot", glyph: "󰜉", command: "systemctl reboot"}
    ]

    function toggle() {
        shown = !shown;
    }

    function run(action) {
        shown = false;
        Quickshell.execDetached(["sh", "-c", action.command]);
    }

    visible: shown
    screen: Niri.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    contentItem {
        focus: root.shown
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.shown = false;
                return;
            }
            const action = root.actions.find(a => a.key === event.text.toLowerCase());
            if (action)
                root.run(action);
        }
    }

    Rectangle {
        color: Theme.background
        opacity: 0.88
        anchors.fill: parent
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.shown = false
    }

    GridLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.75, 900)
        height: Math.min(parent.height * 0.5, 150)
        rows: 1
        columnSpacing: 10

        Repeater {
            model: root.actions

            Rectangle {
                id: tile

                required property var modelData

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: tileArea.containsMouse ? Theme.highlight : "transparent"
                border.width: 1
                border.color: tileArea.containsMouse ? Theme.accent : Theme.highlight

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: tile.modelData.glyph
                        color: Theme.primary
                        font.pixelSize: 34
                        font.family: Theme.fontFamily
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: tile.modelData.label
                        color: Theme.foreground
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "[" + tile.modelData.key + "]"
                        color: Theme.muted
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: tileArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.run(tile.modelData)
                }
            }
        }
    }
}
