import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

PopupPanel {
    id: root

    alignment: "center"
    panelWidth: 620
    panelHeight: 480
    exclusiveKeyboard: true

    property string query: ""
    property int selectedIndex: 0

    readonly property var matchingWindows: {
        const needle = query.trim().toLowerCase();
        const items = Niri.windows.slice().sort((a, b) => {
            if (a.is_focused !== b.is_focused)
                return a.is_focused ? -1 : 1;
            return String(a.title).localeCompare(String(b.title));
        });
        if (needle === "")
            return items;
        return items.filter(window => (String(window.title) + " " + String(window.app_id)).toLowerCase().includes(needle));
    }

    function activate(window) {
        if (!window)
            return;
        close();
        Niri.focusWindow(window);
    }

    function move(delta) {
        const count = matchingWindows.length;
        if (count === 0)
            return;
        selectedIndex = ((selectedIndex + delta) % count + count) % count;
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    onShownChanged: {
        if (!shown)
            return;
        input.text = "";
        selectedIndex = 0;
        Qt.callLater(() => input.forceActiveFocus());
    }

    Column {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            width: parent.width
            height: 36
            radius: 8
            color: Theme.surface

            Text {
                visible: root.query === ""
                text: "Search windows…"
                color: Theme.muted
                font.pixelSize: 13
                font.family: Theme.fontFamily
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
            }

            TextInput {
                id: input
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.foreground
                font.pixelSize: 13
                font.family: Theme.fontFamily
                clip: true
                onTextChanged: {
                    root.query = text;
                    root.selectedIndex = 0;
                }
                Keys.onUpPressed: root.move(-1)
                Keys.onDownPressed: root.move(1)
                Keys.onTabPressed: root.move(1)
                Keys.onBacktabPressed: root.move(-1)
                Keys.onReturnPressed: root.activate(root.matchingWindows[root.selectedIndex])
                Keys.onEnterPressed: root.activate(root.matchingWindows[root.selectedIndex])
                Keys.onEscapePressed: root.close()
            }
        }

        Text {
            visible: root.matchingWindows.length === 0
            text: "No matching windows"
            color: Theme.muted
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - 46
            clip: true
            spacing: 6
            model: root.matchingWindows
            currentIndex: root.selectedIndex

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index

                readonly property var workspace: Niri.workspaces.find(ws => ws.id === modelData.workspace_id) ?? null

                width: list.width
                height: 52
                radius: 8
                color: index === root.selectedIndex ? Theme.highlight : Theme.surface
                border.width: modelData.is_urgent ? 1 : 0
                border.color: Theme.danger

                Text {
                    text: row.modelData.is_floating ? "󰉈" : "󰖯"
                    color: row.modelData.is_focused ? Theme.accent : Theme.primary
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                }

                Column {
                    anchors {
                        left: parent.left
                        leftMargin: 44
                        right: workspaceText.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 2

                    Text {
                        width: parent.width
                        text: row.modelData.title || row.modelData.app_id || "Untitled"
                        color: Theme.foreground
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                        font.bold: row.modelData.is_focused
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: row.modelData.app_id || "unknown"
                        color: Theme.muted
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: workspaceText
                    text: row.workspace?.name || (row.workspace ? String(row.workspace.idx) : "—")
                    color: Theme.muted
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    anchors {
                        right: parent.right
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selectedIndex = row.index
                    onClicked: root.activate(row.modelData)
                }
            }
        }
    }
}
