import Quickshell
import QtQuick
import QtQuick.Layouts

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
        color: Theme.base00

        ColumnLayout {
            anchors.fill: parent

            // Top section - Workspaces
            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 4
                spacing: 0

                Workspaces {
                    number: 6
                }
            }

            // Spacer to push system info to bottom
            Item {
                Layout.fillHeight: true
            }

            // Bottom section - System Info
            ColumnLayout {
                Layout.alignment: Qt.AlignBottom
                spacing: 10

                Battery {}
                Calendar {}
                Logout {}
            }
        }
    }
}
