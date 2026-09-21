import QtQuick
import qs.Common

// A nerd-font glyph button for the vertical bar.
Item {
    id: root

    property string glyph: ""
    property color color: Theme.foreground
    property int size: 15
    property string label: ""
    property color labelColor: Theme.muted
    property bool bold: false
    // Exposed so a flyout can stay open while the pointer is on its anchor.
    readonly property bool hovered: mouseArea.containsMouse

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
            font.bold: root.bold
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            visible: root.label !== ""
            text: root.label
            color: root.labelColor
            font.pixelSize: 10
            font.family: Theme.fontFamily
            font.bold: true
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
