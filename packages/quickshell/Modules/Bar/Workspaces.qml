import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services

// niri workspaces for this bar's output. Empty workspaces are hidden
// unless active or urgent, so the column stays short.
Repeater {
    id: root

    required property string output

    model: Niri.workspacesOn(output).filter(
        ws => ws.active_window_id !== null || ws.is_active || ws.is_urgent)

    Item {
        id: entry

        required property var modelData

        Layout.fillWidth: true
        Layout.preferredHeight: width
        Layout.alignment: Qt.AlignCenter

        // Named workspaces w0..w9 map to keys Mod+1..Mod+0.
        readonly property string label: {
            const name = entry.modelData.name;
            if (name !== null && /^w\d$/.test(name))
                return String((parseInt(name.slice(1)) + 1) % 10);
            return name !== null && name !== "" ? name[0] : String(entry.modelData.idx);
        }

        Rectangle {
            width: parent.width * 0.8
            height: width
            radius: width / 2
            anchors.centerIn: parent

            color: entry.modelData.is_urgent
                ? Theme.danger
                : entry.modelData.is_active
                    ? Theme.accent
                    : Theme.highlight

            Text {
                text: entry.label
                color: entry.modelData.is_active ? Theme.background : Theme.foreground
                font.pixelSize: 11
                font.family: Theme.fontFamily
                font.bold: true
                anchors.centerIn: parent
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Niri.focusWorkspace(entry.modelData)
        }
    }
}
