import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.Widgets
import qs.Common

Osd {
	readonly property bool isMuted: Pipewire.defaultAudioSink?.audio.muted || null
	value: Pipewire.defaultAudioSink?.audio.volume || 0.0

	PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource, ...Pipewire.nodes.values.filter(n => n.isStream)]; }

	onIsMutedChanged: show();
	onValueChanged: show();

	iconUpdater: function () {
		if (isMuted || !value > 0) return Quickshell.iconPath("audio-volume-muted");
			switch (Math.round(value / 0.5) * 0.5) {
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
}
