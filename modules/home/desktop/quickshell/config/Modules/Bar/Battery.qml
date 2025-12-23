import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.Widgets
import qs.Services
import qs.Common

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: width
    Layout.alignment: Qt.AlignCenter

    BatteryService {
        id: bat
    }

	ColoredIcon {
	    width: 22
	    height: 22
        source: Quickshell.iconPath(bat.icon)
        color: Theme.base0D
        brightness: 0.5
	}
}
