pragma Singleton
import QtQml 2.15
import QtQuick 2.15

QtObject {
    id: appPalette

    // defaults
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

    function load(path) {
        console.log("AppPalette.load() path:", path)
        var xhr = new XMLHttpRequest();
        xhr.open("GET", path);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) { // status 0 for file:// in some engines
                    try {
                        var p = JSON.parse(xhr.responseText);
                        for (var k in p) {
                            if (p.hasOwnProperty(k) && appPalette.hasOwnProperty(k)) appPalette[k] = "#" + p[k];
                        }
                        console.log("AppPalette: palette loaded");
                    } catch(e) {
                        console.error("AppPalette: JSON parse failed:", e);
                    }
                } else {
                    console.warn("AppPalette: failed to load", path, "status:", xhr.status);
                }
            }
        }
        xhr.send();
    }
}
