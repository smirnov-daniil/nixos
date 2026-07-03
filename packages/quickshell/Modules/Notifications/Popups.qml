import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Common
import qs.Services

// Notification popups, top-right of the focused screen.
PanelWindow {
    id: root

    visible: Notifs.popups.length > 0
    screen: Niri.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        right: true
    }
    margins {
        top: 8
        right: 8
    }

    implicitWidth: 360
    implicitHeight: stack.implicitHeight

    mask: Region {
        item: stack
    }

    Column {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.popups

            Rectangle {
                id: popup

                required property Notification modelData

                width: stack.width
                implicitHeight: layout.implicitHeight + 20
                radius: 10
                color: Theme.background
                border.width: 1
                border.color: popup.modelData.urgency === NotificationUrgency.Critical
                    ? Theme.danger
                    : Theme.highlight

                Timer {
                    interval: Notifs.timeoutFor(popup.modelData)
                    running: !hoverArea.containsMouse
                    onTriggered: popup.modelData.expire()
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: popup.modelData.dismiss()
                }

                Row {
                    id: layout

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 10
                    }
                    spacing: 10

                    Image {
                        id: icon
                        width: 32
                        height: 32
                        visible: source.toString() !== ""
                        asynchronous: true
                        source: {
                            if (popup.modelData.image !== "")
                                return popup.modelData.image;
                            if (popup.modelData.appIcon !== "")
                                return Quickshell.iconPath(popup.modelData.appIcon, "dialog-information");
                            return "";
                        }
                    }

                    Column {
                        width: parent.width - (icon.visible ? 42 : 0)
                        spacing: 3

                        Text {
                            width: parent.width
                            text: popup.modelData.summary
                            color: Theme.foreground
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: popup.modelData.body !== ""
                            text: popup.modelData.body
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
                            visible: popup.modelData.actions.length > 0

                            Repeater {
                                model: popup.modelData.actions

                                Rectangle {
                                    required property NotificationAction modelData

                                    width: actionText.implicitWidth + 16
                                    height: 22
                                    radius: 6
                                    color: Theme.surface

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
                    }
                }
            }
        }
    }
}
