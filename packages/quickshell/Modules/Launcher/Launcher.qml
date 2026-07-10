import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

// App launcher over DesktopEntries: type to filter, Enter to launch.
PopupPanel {
    id: root

    alignment: "center"
    panelWidth: 520
    panelHeight: 440
    exclusiveKeyboard: true

    property string query: ""
    property int selectedIndex: 0

    readonly property var entries: {
        const all = [...DesktopEntries.applications.values]
            .filter(entry => !entry.noDisplay && entry.name !== "");
        const q = query.toLowerCase().trim();
        if (q === "")
            return all.sort((a, b) => a.name.localeCompare(b.name));
        return all
            .map(entry => ({entry, score: root.score(entry, q)}))
            .filter(item => item.score > 0)
            .sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name))
            .map(item => item.entry);
    }

    function score(entry, q) {
        const name = entry.name.toLowerCase();
        if (name.startsWith(q))
            return 100;
        if (name.split(/\s+/).some(word => word.startsWith(q)))
            return 80;
        if (name.includes(q))
            return 60;
        const haystack = (entry.genericName + " " + entry.keywords.join(" ")).toLowerCase();
        if (haystack.includes(q))
            return 30;
        return 0;
    }

    function launch(entry) {
        if (!entry)
            return;
        root.close();
        // Launch after the keyboard-grabbing surface is gone, so the new
        // window gets focus.
        Qt.callLater(() => {
            if (entry.runInTerminal)
                Quickshell.execDetached(["ghostty", "-e"].concat(entry.command));
            else
                Quickshell.execDetached(entry.command);
        });
    }

    function move(delta) {
        const count = entries.length;
        if (count === 0)
            return;
        selectedIndex = ((selectedIndex + delta) % count + count) % count;
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    onShownChanged: {
        input.text = ""; // syncs query via onTextChanged
        selectedIndex = 0;
        if (shown)
            // The window isn't mapped yet when shown flips; grab focus after
            // the surface exists or the compositor drops the request.
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
                text: "Search apps…"
                color: Theme.muted
                font.pixelSize: 14
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
                font.pixelSize: 14
                font.family: Theme.fontFamily
                clip: true
                focus: root.shown

                onTextChanged: {
                    root.query = text;
                    root.selectedIndex = 0;
                }

                Keys.onUpPressed: root.move(-1)
                Keys.onDownPressed: root.move(1)
                Keys.onTabPressed: root.move(1)
                Keys.onBacktabPressed: root.move(-1)
                Keys.onReturnPressed: root.launch(root.entries[root.selectedIndex])
                Keys.onEnterPressed: root.launch(root.entries[root.selectedIndex])
                Keys.onEscapePressed: root.close()
            }
        }

        ListView {
            id: list

            width: parent.width
            height: parent.height - 46
            clip: true
            model: root.entries
            currentIndex: root.selectedIndex

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index

                width: list.width
                height: 40
                radius: 8
                color: index === root.selectedIndex ? Theme.highlight : "transparent"

                Row {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    spacing: 10

                    Image {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                        asynchronous: true
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: row.modelData.name
                            color: Theme.foreground
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                        }

                        Text {
                            visible: text !== ""
                            text: row.modelData.genericName
                            color: Theme.muted
                            font.pixelSize: 10
                            font.family: Theme.fontFamily
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selectedIndex = row.index
                    onClicked: root.launch(row.modelData)
                }
            }
        }
    }
}
