import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services

// Fullscreen transparent overlay window holding one floating panel.
// Click outside or Escape closes it. Position via `alignment`.
PanelWindow {
    id: root

    property bool shown: false
    property int panelWidth: 340
    property int panelHeight: 420
    // "center" or "bar" (bottom-left, next to the vertical bar)
    property string alignment: "bar"
    property bool exclusiveKeyboard: false
    default property alias content: container.data

    function toggle() {
        shown = !shown;
    }

    function close() {
        shown = false;
    }

    visible: shown
    screen: Niri.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown
        ? (exclusiveKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)
        : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    contentItem {
        focus: root.shown
        Keys.onEscapePressed: root.close()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: panel

        width: root.panelWidth
        height: root.panelHeight
        x: root.alignment === "center" ? (parent.width - width) / 2 : 34
        y: root.alignment === "center" ? (parent.height - height) / 2 : parent.height - height - 8

        radius: 12
        color: Theme.background
        border.width: 1
        border.color: Theme.highlight

        // Eat clicks so they don't fall through to the close area.
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: container
            anchors.fill: parent
            anchors.margins: 14
        }
    }
}
