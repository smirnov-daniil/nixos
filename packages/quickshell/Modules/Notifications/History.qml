import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Common
import qs.Services
import qs.Widgets

// Recent notifications with a clear button.
PopupPanel {
    id: root

    panelWidth: 390
    panelHeight: 560

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
                    width: scheduleText.implicitWidth + 14
                    height: 22
                    radius: 6
                    color: Notifs.scheduledDnd ? Theme.primary : Theme.surface

                    Text {
                        id: scheduleText
                        text: "22–08"
                        color: Notifs.scheduledDnd ? Theme.background : Theme.muted
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Notifs.toggleScheduledDnd()
                    }
                }

                Rectangle {
                    width: dndText.implicitWidth + 16
                    height: 22
                    radius: 6
                    color: Notifs.effectiveDnd ? Theme.warning : Theme.surface

                    Text {
                        id: dndText
                        text: "DND"
                        color: Notifs.effectiveDnd ? Theme.background : Theme.muted
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Notifs.toggleDnd()
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

        Flickable {
            width: parent.width
            height: parent.height - 34
            clip: true
            contentHeight: groups.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: groups
                width: parent.width
                spacing: 12

                Repeater {
                    model: Notifs.groupedHistory

                    Column {
                        id: group
                        required property var modelData

                        width: groups.width
                        spacing: 6

                        Row {
                            spacing: 6

                            Text {
                                text: group.modelData.appName
                                color: Theme.accent
                                font.pixelSize: 10
                                font.family: Theme.fontFamily
                                font.bold: true
                            }

                            Text {
                                text: String(group.modelData.entries.length)
                                color: Theme.muted
                                font.pixelSize: 9
                                font.family: Theme.fontFamily
                            }
                        }

                        Repeater {
                            model: group.modelData.entries

                            Rectangle {
                                id: row
                                required property var modelData

                                width: group.width
                                implicitHeight: content.implicitHeight + 16
                                radius: 8
                                color: Theme.surface
                                border.width: modelData.urgency === NotificationUrgency.Critical ? 1 : 0
                                border.color: Theme.danger

                                Row {
                                    id: content
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 8
                                    }
                                    spacing: 8

                                    Image {
                                        id: icon
                                        width: 32
                                        height: 32
                                        visible: source.toString() !== ""
                                        asynchronous: true
                                        source: {
                                            if (row.modelData.image)
                                                return row.modelData.image;
                                            if (row.modelData.appIcon)
                                                return Quickshell.iconPath(row.modelData.appIcon, "dialog-information");
                                            return "";
                                        }
                                    }

                                    Column {
                                        width: parent.width - (icon.visible ? 40 : 0)
                                        spacing: 3

                                        Row {
                                            width: parent.width

                                            Text {
                                                width: parent.width - dismiss.width
                                                text: row.modelData.summary
                                                color: Theme.foreground
                                                font.pixelSize: 12
                                                font.family: Theme.fontFamily
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                id: dismiss
                                                text: "󰅖"
                                                color: Theme.muted
                                                font.pixelSize: 11
                                                font.family: Theme.fontFamily

                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.margins: -6
                                                    onClicked: Notifs.dismissHistory(row.modelData.key)
                                                }
                                            }
                                        }

                                        Text {
                                            width: parent.width
                                            visible: row.modelData.body !== ""
                                            text: row.modelData.body
                                            color: Theme.muted
                                            font.pixelSize: 11
                                            font.family: Theme.fontFamily
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 4
                                            elide: Text.ElideRight
                                            textFormat: Text.StyledText
                                        }

                                        Row {
                                            spacing: 6
                                            visible: row.modelData.live !== null && row.modelData.live.actions.length > 0

                                            Repeater {
                                                model: row.modelData.live?.actions ?? []

                                                Rectangle {
                                                    required property NotificationAction modelData

                                                    width: actionText.implicitWidth + 14
                                                    height: 22
                                                    radius: 6
                                                    color: Theme.highlight

                                                    Text {
                                                        id: actionText
                                                        text: parent.modelData.text
                                                        color: Theme.foreground
                                                        font.pixelSize: 10
                                                        font.family: Theme.fontFamily
                                                        anchors.centerIn: parent
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: parent.modelData.invoke()
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            visible: row.modelData.live?.hasInlineReply ?? false
                                            width: parent.width
                                            height: 28
                                            radius: 6
                                            color: Theme.background

                                            TextInput {
                                                anchors {
                                                    fill: parent
                                                    leftMargin: 8
                                                    rightMargin: 8
                                                }
                                                verticalAlignment: TextInput.AlignVCenter
                                                color: Theme.foreground
                                                font.pixelSize: 10
                                                font.family: Theme.fontFamily
                                                clip: true
                                                Keys.onReturnPressed: {
                                                    if (text !== "") {
                                                        row.modelData.live.sendInlineReply(text);
                                                        text = "";
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            text: Qt.formatDateTime(row.modelData.time, "ddd HH:mm")
                                            color: Theme.muted
                                            font.pixelSize: 9
                                            font.family: Theme.fontFamily
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
