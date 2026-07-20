import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.Common

// ext-session-lock screen: type password, Enter to unlock, Escape clears.
// Uses the "login" PAM config (PamContext default) so it works on both
// NixOS and Ubuntu without extra pam.d entries.
Scope {
    id: root

    // Shared across all screens' surfaces so every monitor shows the same
    // input state, whichever one has keyboard focus.
    property string password: ""
    property string error: ""

    function lock() {
        sessionLock.locked = true;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PamContext {
        id: pam

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }

        onCompleted: result => {
            root.password = "";
            if (result === PamResult.Success) {
                root.error = "";
                sessionLock.locked = false;
            } else {
                root.error = "Authentication failed";
            }
        }
    }

    WlSessionLock {
        id: sessionLock

        locked: false

        WlSessionLockSurface {
            Rectangle {
                anchors.fill: parent
                color: Theme.background

                Item {
                    anchors.fill: parent
                    focus: true

                    Keys.onPressed: event => {
                        if (pam.active)
                            return;
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.error = "";
                            pam.start();
                        } else if (event.key === Qt.Key_Backspace) {
                            root.password = root.password.slice(0, -1);
                        } else if (event.key === Qt.Key_Escape) {
                            root.password = "";
                        } else if (event.text.length === 1 && event.text.charCodeAt(0) >= 0x20) {
                            root.password += event.text;
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Theme.foreground
                        font.pixelSize: 72
                        font.family: Theme.fontFamily
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                        color: Theme.muted
                        font.pixelSize: 16
                        font.family: Theme.fontFamily
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Item {
                        width: 1
                        height: 24
                    }

                    Rectangle {
                        width: 260
                        height: 40
                        radius: 10
                        color: Theme.surface
                        border.width: 1
                        border.color: root.error !== "" ? Theme.danger : Theme.highlight
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (pam.active)
                                    return "verifying…";
                                if (root.password.length > 0)
                                    return "●".repeat(root.password.length);
                                return "enter password";
                            }
                            color: root.password.length > 0 ? Theme.foreground : Theme.muted
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                        }
                    }

                    Text {
                        visible: root.error !== ""
                        text: root.error
                        color: Theme.danger
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                Text {
                    text: "󰌾"
                    color: Theme.muted
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: 32
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
