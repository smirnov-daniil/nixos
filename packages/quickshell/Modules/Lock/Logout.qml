import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

// Logout Button
Item {
    Layout.fillWidth: true
    Layout.preferredHeight: width
    Layout.alignment: Qt.AlignCenter

    // Logout widget
    LogoutWidget {
        id: logoutWidget

        LogoutButton {
            command: "loginctl lock-session"
            keybind: Qt.Key_L
            text: "Lock"
            icon: Quickshell.iconPath("system-lock-screen")
        }

        LogoutButton {
            command: "loginctl terminate-user $USER"
            keybind: Qt.Key_E
            text: "Logout"
            icon: Quickshell.iconPath("system-log-out")
        }

        LogoutButton {
            command: "systemctl suspend"
            keybind: Qt.Key_U
            text: "Suspend"
            icon: Quickshell.iconPath("system-suspend")
        }

        LogoutButton {
            command: "systemctl hibernate"
            keybind: Qt.Key_H
            text: "Hibernate"
            icon: Quickshell.iconPath("system-suspend-hibernate")
        }

        LogoutButton {
            command: "systemctl poweroff"
            keybind: Qt.Key_S
            text: "Shutdown"
            icon: Quickshell.iconPath("system-shutdown")
        }

        LogoutButton {
            command: "systemctl reboot"
            keybind: Qt.Key_R
            text: "Reboot"
            icon: Quickshell.iconPath("system-reboot")
        }
    }

	ColoredIcon {
	    width: 24
	    height: 24
        source: Quickshell.iconPath("system-shutdown")
        color: Theme.base0D
	}

    MouseArea {
        id: logoutButtonMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: logoutWidget.toggle()
    }
}
