import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "components" as Components

ShellRoot {
    id: root

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    // System info properties
    property int batteryCapacity: 0
    property string xdgConfigHome: ""

    // Battery
    Process {
        id: batteryProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 0"]
        stdout: SplitParser {
            onRead: data => batteryCapacity = parseInt(data) || 0
        }
        Component.onCompleted: running = true
    }

    Process {
        id: xdgProc
        command: ["sh", "-c", "echo -n $XDG_CONFIG_HOME"]
        stdout: SplitParser {
            onRead: data => {
                xdgConfigHome = data
                Components.AppPalette.load(xdgConfigHome + "/stylix/palette.json")
            }
        }
        Component.onCompleted: running = true
    }

    // Slow timer for system stats
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            batteryProc.running = true
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                bottom: true
            }

            implicitWidth: 24
            color: Components.AppPalette.base00

            margins {
                top: 0
                bottom: 0
                left: 0
                right: 0
            }

            Rectangle {
                anchors.fill: parent
                color: Components.AppPalette.base00

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Top section - Logo and Workspaces
                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 6
                        Layout.fillWidth: true
                        spacing: 6

                        // Workspaces - tighter layout
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4

                            Repeater {
                                model: 6

                                Item {
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 20
                                    Layout.alignment: Qt.AlignHCenter

                                    property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1) ?? null
                                    property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                                    property bool hasWindows: workspace !== null

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: parent.isActive ? Components.AppPalette.base0C : (parent.hasWindows ? Components.AppPalette.base02 : "transparent")
                                        anchors.centerIn: parent

                                        Text {
                                            text: index + 1
                                            color: parent.parent.isActive ? Components.AppPalette.base00 : Components.AppPalette.base0C
                                            font.pixelSize: 14
                                            font.family: root.fontFamily
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: Hyprland.dispatch("workspace " + (index + 1))
                                    }
                                }
                            }
                        }
                    }

                    // Spacer to push system info to bottom
                    Item {
                        Layout.fillHeight: true
                    }

                    // Bottom section - System Info (tight)
                    ColumnLayout {
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 16
                        Layout.fillWidth: true
                        spacing: 8

                        // Battery
                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignHCenter

                            Text {
                                text: batteryCapacity
                                color: Components.AppPalette.base0D
                                font.pixelSize: 10
                                font.family: root.fontFamily
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            Text {
                                text: "B"
                                color: Components.AppPalette.base0D
                                font.pixelSize: 10
                                font.family: root.fontFamily
                                anchors {
                                    top: parent.bottom
                                    topMargin: -2
                                    horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // Calendar/Time
                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignHCenter

                            Text {
                                id: clockHour
                                text: Qt.formatDateTime(new Date(), "HH")
                                color: Components.AppPalette.base0C
                                font.pixelSize: 10
                                font.family: root.fontFamily
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            Text {
                                id: clockDate
                                text: Qt.formatDateTime(new Date(), "dd")
                                color: Components.AppPalette.base0C
                                font.pixelSize: 10
                                font.family: root.fontFamily
                                anchors {
                                    top: parent.bottom
                                    topMargin: -2
                                    horizontalCenter: parent.horizontalCenter
                                }
                            }

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: {
                                    clockHour.text = Qt.formatDateTime(new Date(), "HH")
                                    clockDate.text = Qt.formatDateTime(new Date(), "dd")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
