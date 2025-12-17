import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Widgets
import qs.Common

Osd {
	value: currentBrightness / maxBrightness

	property int maxBrightness
	property int currentBrightness

	onCurrentBrightnessChanged: show()

	iconUpdater: function () {
		switch (Math.round(value / (1 / 3)) * (1 / 3)) {
			case 0:
				return Quickshell.iconPath("display-brightness-off");
			case 1 / 3:
				return Quickshell.iconPath("display-brightness-low");
			case 2 / 3:
				return Quickshell.iconPath("display-brightness-medium");
			case 1.0:
				return Quickshell.iconPath("display-brightness-high");
			default:
				return Quickshell.iconPath("display-brightness");
		}
	}

	Process {
		running: true
		command: ["brightnessctl", "max"]
		stdout: StdioCollector {
			onStreamFinished: {
				maxBrightness = parseInt(text)
			}
		}
	}

	Process {
		id: getCurrentBrightness
		running: true
		command: ["brightnessctl", "get"]
		stdout: StdioCollector {
			onStreamFinished: {
				currentBrightness = parseInt(text)
			}
		}
	}

	Process {
		running: true
		command: ["udevadm", "monitor", "--subsystem-match=backlight"]
		stdout: SplitParser {
			splitMarker: "UDEV"
			onRead: getCurrentBrightness.running = true
		}
	}
}
