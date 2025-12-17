import QtQuick
import QtQuick.Effects

Item {
    property string source: ""
    property color color: "#ffffff"
    property real brightness: 0

    Image {
		anchors.centerIn: parent
		width: parent.width
		height: parent.height
        id: icon
        source: parent.source
        visible: false
    }

    MultiEffect {
        source: icon
        anchors.fill: icon
        colorization: 1.0 
        colorizationColor: parent.color
        brightness: parent.brightness
    }
}
