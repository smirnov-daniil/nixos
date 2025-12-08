import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    // Theme colors
    property color base00: "#292c36"
    property color base01: "#333344"
    property color base02: "#474160"
    property color base03: "#65568a"
    property color base04: "#b8b8b8"
    property color base05: "#d8d8d8"
    property color base06: "#e8e8e8"
    property color base07: "#f8f8f8"
    property color base08: "#f84547"
    property color base09: "#d28e5d"
    property color base0A: "#efa16b"
    property color base0B: "#95c76f"
    property color base0C: "#64878f"
    property color base0D: "#8485ce"
    property color base0E: "#b74989"
    property color base0F: "#986841"

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    // System info properties
    property int batteryCapacity: 0

    // Battery
    Process {
        id: batteryProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 0"]
        stdout: SplitParser {
            onRead: data => {
                batteryCapacity = parseInt(data) || 0
            }
        }
        Component.onCompleted: running = true
    }

    function loadColorPalette() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "$XDG_CONFIG_HOME/stylix/palette.json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try {
                    var palette = JSON.parse(xhr.responseText);
                    base00 = palette.base00;
                    base01 = palette.base01;
                    base02 = palette.base02;
                    base03 = palette.base03;
                    base04 = palette.base04;
                    base05 = palette.base05;
                    base06 = palette.base06;
                    base07 = palette.base07;
                    base08 = palette.base08;
                    base09 = palette.base09;
                    base0A = palette.base0A;
                    base0B = palette.base0B;
                    base0C = palette.base0C;
                    base0D = palette.base0D;
                    base0E = palette.base0E;
                    base0F = palette.base0F;
                    console.log("Palette loaded:", colorData.scheme);
                } catch(e) {
                    console.error("Failed to parse palette.json:", e);
                }
            }
        }
        xhr.send();
    }

    Component.onCompleted: loadColorPalette()

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
            color: root.base00

            margins {
                top: 0
                bottom: 0
                left: 0
                right: 0
            }

            Rectangle {
                anchors.fill: parent
                color: root.base00

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
                                        color: parent.isActive ? root.base0C : (parent.hasWindows ? root.base02 : "transparent")
                                        anchors.centerIn: parent

                                        Text {
                                            text: index + 1
                                            color: parent.parent.isActive ? root.base00 : root.base0C
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
                                color: root.base0D
                                font.pixelSize: 10
                                font.family: root.fontFamily
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            Text {
                                text: "B"
                                color: root.base0D
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
                                color: root.base0C
                                font.pixelSize: 10
                                font.family: root.fontFamily
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            Text {
                                id: clockDate
                                text: Qt.formatDateTime(new Date(), "dd")
                                color: root.base0C
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
