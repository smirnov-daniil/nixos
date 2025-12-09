pragma Singleton
import Quickshell
import QtQml 2.15
import QtQuick 2.15

QtObject {
    id: appPalette

    // Default Porple theme colors
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

    // Helper properties
    property color background: base00
    property color foreground: base05
    property color primary: base0D
    property color secondary: base0E
    property color success: base0B
    property color warning: base0A
    property color danger: base08

    function load(path) {
        console.log("AppPalette.load() path:", path)
        var xhr = new XMLHttpRequest()
        xhr.open("GET", path)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var p = JSON.parse(xhr.responseText)
                        for (var k in p) {
                            if (p.hasOwnProperty(k) && appPalette.hasOwnProperty(k)) {
                                // Ensure proper hex format
                                var hexValue = p[k]
                                if (typeof hexValue === 'string') {
                                    // Add # if missing
                                    var colorValue = hexValue.startsWith('#') ? hexValue : '#' + hexValue
                                    // Validate it's a proper color
                                    try {
                                        // Use Qt.rgba to validate color
                                        var colorObj = Qt.color(colorValue)
                                        if (colorObj) {
                                            appPalette[k] = colorValue
                                        }
                                    } catch(e) {
                                        console.warn("Invalid color format for", k, ":", hexValue)
                                    }
                                }
                            }
                        }
                        console.log("AppPalette: palette loaded from", path)
                    } catch(e) {
                        console.error("AppPalette: JSON parse failed:", e)
                    }
                } else {
                    console.warn("AppPalette: failed to load", path, "status:", xhr.status)
                }
            }
        }
        xhr.send()
    }

    Component.onCompleted: {
        appPalette.load(Quickshell.env("XDG_CONFIG_HOME") + "/stylix/palette.json")
    }
}
