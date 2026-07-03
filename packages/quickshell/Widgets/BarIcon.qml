import QtQuick
import qs.Common

// A nerd-font glyph button for the vertical bar.
Item {
    id: root

    property string glyph: ""
    property color color: Theme.foreground
    property int size: 15
    property string label: ""

    signal clicked(var mouse)

    implicitWidth: parent ? parent.width : 24
    implicitHeight: column.implicitHeight + 8

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Theme.highlight
        opacity: mouseArea.containsMouse ? 0.6 : 0
    }

    Column {
        id: column
        anchors.centerIn: parent
        spacing: 0

        Text {
            text: root.glyph
            color: root.color
            font.pixelSize: root.size
            font.family: Theme.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            visible: root.label !== ""
            text: root.label
            color: Theme.muted
            font.pixelSize: 8
            font.family: Theme.fontFamily
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
    }
}
