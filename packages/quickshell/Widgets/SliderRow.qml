import QtQuick
import qs.Common

// Glyph + horizontal slider. Emits moved(value) while dragging.
Item {
    id: root

    property string glyph: ""
    property real value: 0 // 0..1
    property color fillColor: Theme.accent

    signal moved(real value)

    implicitHeight: 26

    Text {
        id: icon
        text: root.glyph
        color: Theme.foreground
        font.pixelSize: 15
        font.family: Theme.fontFamily
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        id: track
        anchors {
            left: icon.right
            leftMargin: 10
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: 8
        radius: 4
        color: Theme.highlight

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * Math.max(0, Math.min(1, root.value))
            radius: parent.radius
            color: root.fillColor
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6

            function update(mouse) {
                const v = Math.max(0, Math.min(1, (mouse.x - 6) / track.width));
                root.moved(v);
            }

            onPressed: mouse => update(mouse)
            onPositionChanged: mouse => {
                if (pressed)
                    update(mouse);
            }
        }
    }
}
