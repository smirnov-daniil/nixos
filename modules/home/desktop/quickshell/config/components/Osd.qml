import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

Scope {
    id: osd

    property real value: 0
    property bool active: false
    property int timeout: 1000
    property string _icon: ""
    property var iconUpdater: function() { return "" }

    function show() {
        osd.active = true
        hideTimer.restart()
        _icon = osd.iconUpdater()
    }
    
	Timer {
		id: hideTimer
		interval: osd.timeout
		onTriggered: osd.active = false
	}

	LazyLoader {
		active: osd.active

		PanelWindow {
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
						source: _icon
					}

					Rectangle {
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
							implicitWidth: parent.width * osd.value
							radius: parent.radius
						}
					}
				}
			}
		}
	}
}
