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

	onIsMutedChanged: show();
	onVolumeChanged: show();

	function show() {
		root.shouldShowOsd = true;
		hideTimer.restart();
		currentIcon = updateIcon();
	}

	property bool shouldShowOsd: false
	property string currentIcon: Quickshell.iconPath("audio-volume-high-symbolic")

	function updateIcon() {
		if (isMuted || !volume > 0) return Quickshell.iconPath("audio-volume-muted");
			switch (Math.round(volume /0.5) *0.5) {
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

	Timer {
		id: hideTimer
		interval: 1000
		onTriggered: root.shouldShowOsd = false
	}

	// The OSD window will be created and destroyed based on shouldShowOsd.
	// PanelWindow.visible could be set instead of using a loader, but using
	// a loader will reduce the memory overhead when the window isn't open.
	LazyLoader {
		active: root.shouldShowOsd

		PanelWindow {
			// Since the panel's screen is unset, it will be picked by the compositor
			// when the window is created. Most compositors pick the current active monitor.

			anchors.bottom: true
			margins.bottom: screen.height / 40
			exclusiveZone: 0

			implicitWidth: 400
			implicitHeight: 50
			color: "transparent"

			// An empty click mask prevents the window from blocking mouse events.
			mask: Region {}

			Rectangle {
				anchors.fill: parent
				radius: height / 2
				color: Theme.base01

				RowLayout {
					anchors {
						fill: parent
						leftMargin: 10
						rightMargin: 15
					}

					IconImage {
						implicitSize: 30
						source: root.currentIcon
					}

					Rectangle {
						// Stretches to fill all left-over space
						Layout.fillWidth: true

						implicitHeight: 10
						radius: 20
						color: Theme.base02

						Rectangle {
							anchors {
								left: parent.left
								top: parent.top
								bottom: parent.bottom
							}

							color: Theme.base0C
							implicitWidth: parent.width * volume
							radius: parent.radius
						}
					}
				}
			}
		}
	}
}
