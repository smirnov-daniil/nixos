import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

Scope {
	id: root
	readonly property bool isMuted: Pipewire.defaultAudioSink?.audio.muted || null
	readonly property real volume: Pipewire.defaultAudioSink?.audio.volume || 0.0

	PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource, ...Pipewire.nodes.values.filter(n => n.isStream)]; }

	onIsMutedChanged: soundOSD.show();
	onVolumeChanged: soundOSD.show();

	function updateIcon() {
		if (isMuted || !volume > 0) return Quickshell.iconPath("audio-volume-muted");
			switch (Math.round(volume / 0.5) * 0.5) {
				case 0:
					return Quickshell.iconPath("audio-volume-low");
				case 0.5:
					return Quickshell.iconPath("audio-volume-medium");
				case 1.0:
					return Quickshell.iconPath("audio-volume-high");
				default:
					return Quickshell.iconPath("audio-volume-high");
			}
	}

	OSD {
		id: soundOSD
		value: root.volume
		iconUpdater: root.updateIcon
	}
}
