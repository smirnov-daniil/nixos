import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Variants {
    id: root
    default property list<LogoutButton> buttons
    
    // Visibility property
    property bool visible: false

    model: Quickshell.screens
    delegate: PanelWindow {
        id: windowDelegate
        
        property var modelData
        screen: modelData

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        color: "transparent"
        visible: root.visible  // Bind to root's visible property

        contentItem {
            focus: visible
            Keys.onPressed: event => {
                if (event.key == Qt.Key_Escape) {
                    root.visible = false
                } else {
                    for (let i = 0; i < buttons.length; i++) {
                        let button = buttons[i];
                        if (event.key == button.keybind) {
                            button.exec()
                            root.visible = false
                        }
                    }
                }
            }
        }

        anchors {
            top: true
            left: true
            bottom: true
            right: true
        }

        Rectangle {
            color: Theme.base00
            opacity: 0.95
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: root.visible = false

                GridLayout {
                    anchors.centerIn: parent

                    width: Math.min(parent.width * 0.75, 800)
                    height: Math.min(parent.height * 0.75, 600)

                    columns: 3
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: buttons
                        delegate: Rectangle {
                            required property LogoutButton modelData;

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            radius: 10
                            color: ma.containsMouse ? Theme.base0D : Theme.base01
                            border.width: 2
                            border.color: ma.containsMouse ? Theme.base0C : Theme.base02

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    modelData.exec()
                                    root.visible = false
                                }
                            }

                            Image {
								id: icon
								anchors.centerIn: parent
								source: `icons/${modelData.icon}.png`
								width: parent.width * 0.25
								height: parent.width * 0.25
							}

                            Text {
                                text: modelData.text
                                font.pixelSize: 16
                                font.bold: true
                                color: Theme.base05
                                anchors {
									top: icon.bottom
									topMargin: 20
									horizontalCenter: parent.horizontalCenter
								}
		                    }
                        }
                    }
                }
            }
        }
    }

    // Function to show the logout widget
    function show() {
        visible = true
    }

    // Function to hide the logout widget
    function hide() {
        visible = false
    }

    // Toggle function
    function toggle() {
        visible = !visible
    }
}
