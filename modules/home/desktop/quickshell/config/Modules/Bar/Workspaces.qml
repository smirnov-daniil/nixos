import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.Common

// Workspaces - tighter layout
Repeater {
    property var number: 6

    model: number

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: width
        Layout.alignment: Qt.AlignCenter

        property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1) ?? null
        property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
        property bool hasWindows: workspace !== null

        Rectangle {
            width: parent.width * 0.8
            height: width
            radius: width / 2
            Layout.alignment: Qt.AlignCenter

            color: parent.isActive ? Theme.base0C : (parent.hasWindows ? Theme.base02 : "transparent")
            anchors.centerIn: parent

            Text {
                text: index + 1
                color: parent.parent.isActive ? Theme.base00 : Theme.base0C
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
                anchors.centerIn: parent
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Hyprland.dispatch("workspace " + (index + 1))
        }
    }
}
