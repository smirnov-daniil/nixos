import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.Common

Repeater {
    model: SystemTray.items

    Item {
        id: entry

        required property SystemTrayItem modelData

        Layout.fillWidth: true
        Layout.preferredHeight: 22
        Layout.alignment: Qt.AlignCenter

        Image {
            anchors.centerIn: parent
            width: 16
            height: 16
            source: entry.modelData.icon
            asynchronous: true
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton)
                    entry.modelData.activate();
                else if (mouse.button === Qt.MiddleButton)
                    entry.modelData.secondaryActivate();
                else if (entry.modelData.hasMenu)
                    menuAnchor.open();
            }
        }

        QsMenuAnchor {
            id: menuAnchor
            menu: entry.modelData.menu
            // window is derived from the item; setting both trips a
            // quickshell 0.3.0 null-deref on live reload.
            anchor.item: entry
            anchor.edges: Edges.Right
        }
    }
}
