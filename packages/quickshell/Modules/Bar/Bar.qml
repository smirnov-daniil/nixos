import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets

Variants {
    id: root

    // Panels owned by shell.qml, shared by all screens' bars.
    required property var calendar
    required property var controlCenter
    required property var notificationHistory
    required property var sessionMenu

    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        anchors {
            top: true
            left: true
            bottom: true
        }

        implicitWidth: Theme.barWidth
        color: Theme.background

        ColumnLayout {
            anchors.fill: parent

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 6
                spacing: 2

                Workspaces {
                    output: window.screen.name
                }
            }

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 6
                spacing: 4

                Tray {}

                BarIcon {
                    Layout.fillWidth: true
                    visible: Media.available
                    glyph: Media.activePlayer?.isPlaying ? "󰎆" : "󰏤"
                    color: Media.activePlayer?.isPlaying ? Theme.accent : Theme.muted
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton)
                            Media.activePlayer?.togglePlaying();
                        else if (mouse.button === Qt.RightButton)
                            Media.activePlayer?.next();
                        else
                            root.controlCenter.openTab("audio");
                    }
                }

                BarIcon {
                    Layout.fillWidth: true
                    visible: SystemActions.recording || Niri.screenCasting
                    glyph: SystemActions.recording ? "󰑊" : "󰹑"
                    color: Theme.danger
                    onClicked: {
                        if (SystemActions.recording)
                            SystemActions.toggleRecording();
                    }
                }

                BarIcon {
                    Layout.fillWidth: true
                    visible: Niri.kbLayout !== ""
                    glyph: Niri.kbLayout
                    // Two letters at 10px in base03 were the least legible
                    // thing on the bar; bold, a size up, and readable in both
                    // states rather than only when the layout is non-default.
                    size: 12
                    bold: true
                    color: Niri.kbLayoutIdx === 0 ? Theme.foreground : Theme.warning
                }

                BarIcon {
                    Layout.fillWidth: true
                    glyph: Notifs.effectiveDnd ? "󰂛" : (Notifs.history.length > 0 ? "󰂚" : "󰂜")
                    color: Notifs.effectiveDnd
                        ? Theme.warning
                        : (Notifs.history.length > 0 ? Theme.foreground : Theme.muted)
                    // Right click toggles do-not-disturb.
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            Notifs.toggleDnd();
                        else
                            root.notificationHistory.toggle();
                    }
                }

                Battery {}

                Clock {
                    onClicked: root.calendar.toggle()
                }

                QuickSettings {
                    controlCenter: root.controlCenter
                }

                // BarIcon {
                //     Layout.fillWidth: true
                //     glyph: "󰐥"
                //     color: Theme.danger
                //     onClicked: root.sessionMenu.toggle()
                // }
            }
        }
    }
}
