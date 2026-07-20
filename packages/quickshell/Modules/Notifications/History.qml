import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

// Recent notifications with a clear button.
PopupPanel {
    id: root

    panelWidth: 360
    panelHeight: 480

    Column {
        anchors.fill: parent
        spacing: 10

        Item {
            width: parent.width
            height: 24

            Text {
                text: "Notifications"
                color: Theme.foreground
                font.pixelSize: 14
                font.family: Theme.fontFamily
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                spacing: 6
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: dndText.implicitWidth + 16
                    height: 22
                    radius: 6
                    color: Notifs.dnd ? Theme.warning : Theme.surface

                    Text {
                        id: dndText
                        text: "DND"
                        color: Notifs.dnd ? Theme.background : Theme.muted
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }

                Rectangle {
                    visible: Notifs.history.length > 0
                    width: clearText.implicitWidth + 16
                    height: 22
                    radius: 6
                    color: Theme.surface

                    Text {
                        id: clearText
                        text: "Clear"
                        color: Theme.foreground
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Notifs.clearHistory()
                    }
                }
            }
        }

        Text {
            visible: Notifs.history.length === 0
            text: "Nothing here"
            color: Theme.muted
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }

        ListView {
            width: parent.width
            height: parent.height - 34
            clip: true
            spacing: 8
            model: Notifs.history

            delegate: Rectangle {
                id: row

                required property var modelData

                width: parent ? parent.width : 0
                implicitHeight: content.implicitHeight + 16
                radius: 8
                color: Theme.surface

                Column {
                    id: content

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 8
                    }
                    spacing: 2

                    Row {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: row.modelData.appName || "unknown"
                            color: Theme.accent
                            font.pixelSize: 10
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: Qt.formatDateTime(row.modelData.time, "HH:mm")
                            color: Theme.muted
                            font.pixelSize: 10
                            font.family: Theme.fontFamily
                        }
                    }

                    Text {
                        width: parent.width
                        text: row.modelData.summary
                        color: Theme.foreground
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: row.modelData.body !== ""
                        text: row.modelData.body
                        color: Theme.muted
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        textFormat: Text.StyledText
                    }
                }
            }
        }
    }
}
