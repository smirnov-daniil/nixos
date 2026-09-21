import QtQuick
import Quickshell
import qs.Common

// A hover flyout that opens perpendicular to the vertical bar, anchored to one
// bar item. It stays open while the pointer is over either the anchor or the
// flyout, so the pointer can cross the gap between them. Deliberately without
// animation: the window is shown and hidden outright.
PopupWindow {
    id: root

    required property Item anchorItem
    // Crossing from the bar icon into the flyout leaves both unhovered for a
    // frame or two, so closing waits out that gap rather than acting on it.
    property int closeDelay: 160
    // The anchor's own MouseArea owns its hover state; the bar feeds it in.
    property bool anchorHovered: false

    default property alias flyoutContent: container.data

    readonly property bool hovered: anchorHovered || hoverHandler.hovered

    function forceClose() {
        closeTimer.stop();
        visible = false;
    }

    // container is intentionally unsized so childrenRect measures the content
    // instead of the window, which would be a binding loop.
    implicitWidth: container.childrenRect.width + 16
    implicitHeight: container.childrenRect.height + 16

    color: "transparent"
    visible: false
    grabFocus: false

    anchor {
        item: root.anchorItem
        edges: Edges.Right
        gravity: Edges.Right
    }

    onHoveredChanged: {
        if (hovered) {
            closeTimer.stop();
            visible = true;
        } else {
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer
        interval: root.closeDelay
        onTriggered: root.visible = false
    }

    Item {
        anchors.fill: parent

        HoverHandler {
            id: hoverHandler
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 10
            color: Theme.background
            border.width: 1
            border.color: Theme.highlight
        }

        Item {
            id: container
            x: 8
            y: 8
        }
    }
}
