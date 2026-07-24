import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

PopupPanel {
    id: root

    alignment: "center"
    panelWidth: 560
    panelHeight: 500
    exclusiveKeyboard: true

    property string query: ""
    property int selectedIndex: 0

    readonly property var filteredEntries: {
        const needle = query.trim().toLowerCase();
        if (needle === "")
            return ClipboardStore.entries;
        return ClipboardStore.entries.filter(entry => entry.preview.toLowerCase().includes(needle));
    }

    function choose(entry) {
        if (!entry)
            return;
        ClipboardStore.copy(entry.id);
        close();
    }

    function move(delta) {
        const count = filteredEntries.length;
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
        ClipboardStore.refresh();
        Qt.callLater(() => input.forceActiveFocus());
    }

    Column {
        anchors.fill: parent
        spacing: 10

        Row {
            width: parent.width
            spacing: 8

            Rectangle {
                width: parent.width - clearButton.width - 8
                height: 36
                radius: 8
                color: Theme.surface

                Text {
                    visible: root.query === ""
                    text: "Search clipboard…"
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
                    Keys.onReturnPressed: root.choose(root.filteredEntries[root.selectedIndex])
                    Keys.onEnterPressed: root.choose(root.filteredEntries[root.selectedIndex])
                    Keys.onDeletePressed: {
                        const entry = root.filteredEntries[root.selectedIndex];
                        if (entry)
                            ClipboardStore.remove(entry);
                    }
                    Keys.onEscapePressed: root.close()
                }
            }

            Rectangle {
                id: clearButton
                width: 64
                height: 36
                radius: 8
                color: Theme.surface

                Text {
                    text: "Clear"
                    color: Theme.danger
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: ClipboardStore.clear()
                }
            }
        }

        Text {
            visible: !ClipboardStore.loading && root.filteredEntries.length === 0
            text: "Clipboard is empty"
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
            model: root.filteredEntries
            currentIndex: root.selectedIndex

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index

                width: list.width
                height: 48
                radius: 8
                color: index === root.selectedIndex ? Theme.highlight : Theme.surface

                Text {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 36
                    }
                    verticalAlignment: Text.AlignVCenter
                    text: row.modelData.preview
                    color: Theme.foreground
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                }

                Text {
                    text: "󰆴"
                    color: Theme.muted
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                    anchors {
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        onClicked: ClipboardStore.remove(row.modelData)
                    }
                }

                MouseArea {
                    anchors {
                        left: parent.left
                        right: parent.right
                        rightMargin: 34
                        top: parent.top
                        bottom: parent.bottom
                    }
                    hoverEnabled: true
                    onEntered: root.selectedIndex = row.index
                    onClicked: root.choose(row.modelData)
                }
            }
        }
    }
}
