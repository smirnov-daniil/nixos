pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: [...Mpris.players.values]
    readonly property var activePlayer: players.find(player => player.isPlaying) ?? players[0] ?? null
    readonly property bool available: activePlayer !== null

    function formatTime(seconds) {
        if (!Number.isFinite(seconds) || seconds < 0)
            return "0:00";
        const rounded = Math.floor(seconds);
        return Math.floor(rounded / 60) + ":" + String(rounded % 60).padStart(2, "0");
    }

    function select(player) {
        if (player)
            player.raise();
    }
}
