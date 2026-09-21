pragma Singleton
import Quickshell
import QtQuick

QtObject {
    id: theme

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    // Width of the vertical bar; panels sit just clear of it.
    property int barWidth: 32

    // Fallback palette, overridden from theme.nix via QS_FLAKE_THEME (set by
    // the nix wrapper in packages/quickshell/default.nix).
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

    // Semantic aliases
    property color background: base00
    property color surface: base01
    property color highlight: base02
    property color muted: base03
    property color foreground: base05
    property color primary: base0D
    property color accent: base0C
    property color success: base0B
    property color warning: base0A
    property color danger: base08

    function _apply(raw) {
        try {
            const palette = JSON.parse(raw);
            for (const key in palette) {
                if (!theme.hasOwnProperty(key))
                    continue;
                const value = String(palette[key]);
                theme[key] = value.startsWith("#") ? value : "#" + value;
            }
        } catch (e) {
            console.error("Theme: failed to parse theme file:", e);
        }
    }

    Component.onCompleted: {
        const path = Quickshell.env("QS_FLAKE_THEME_FILE");
        if (!path)
            return;
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + path);
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0))
                theme._apply(xhr.responseText);
        };
        xhr.send();
    }
}
