import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

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
            keybind: Qt.Key_K
            text: "Lock"
            icon: "lock"
        }

        LogoutButton {
            command: "loginctl terminate-user $USER"
            keybind: Qt.Key_E
            text: "Logout"
            icon: "logout"
        }

        LogoutButton {
            command: "systemctl suspend"
            keybind: Qt.Key_U
            text: "Suspend"
            icon: "suspend"
        }

        LogoutButton {
            command: "systemctl hibernate"
            keybind: Qt.Key_H
            text: "Hibernate"
            icon: "hibernate"
        }

        LogoutButton {
            command: "systemctl poweroff"
            keybind: Qt.Key_S
            text: "Shutdown"
            icon: "shutdown"
        }

        LogoutButton {
            command: "systemctl reboot"
            keybind: Qt.Key_R
            text: "Reboot"
            icon: "reboot"
        }
    }

    Image {
		anchors.centerIn: parent
		source: "icons/shutdown.png"
		width: 14
		height: 14
	}

    MouseArea {
        id: logoutButtonMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: logoutWidget.toggle()
    }
}
