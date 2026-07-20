import QtQuick
import qs.Common
import qs.Widgets

// Month calendar popup for the bar clock: read-only, Monday-first,
// today highlighted, ‹ › to change month. Reopening resets to today.
PopupPanel {
    id: root

    panelWidth: 280
    panelHeight: 300

    property date today: new Date()
    property date viewDate: new Date()

    readonly property int cellWidth: 36
    readonly property var cells: {
        const first = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1);
        const start = new Date(first);
        start.setDate(1 - (first.getDay() + 6) % 7);
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start);
            d.setDate(start.getDate() + i);
            out.push(d);
        }
        return out;
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    function shiftMonth(delta) {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + delta, 1);
    }

    onShownChanged: {
        if (shown) {
            today = new Date();
            viewDate = new Date();
        }
    }

    Column {
        anchors.fill: parent
        spacing: 10

        Item {
            width: parent.width
            height: 24

            Text {
                text: "󰅁"
                color: Theme.muted
                font.pixelSize: 16
                font.family: Theme.fontFamily
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: root.shiftMonth(-1)
                }
            }

            Text {
                text: Qt.formatDate(root.viewDate, "MMMM yyyy")
                color: Theme.foreground
                font.pixelSize: 14
                font.family: Theme.fontFamily
                font.bold: true
                anchors.centerIn: parent
            }

            Text {
                text: "󰅂"
                color: Theme.muted
                font.pixelSize: 16
                font.family: Theme.fontFamily
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: root.shiftMonth(1)
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: 7

                Text {
                    required property int index

                    width: root.cellWidth
                    text: Qt.locale().dayName((index + 1) % 7, Locale.ShortFormat)
                    color: Theme.muted
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Grid {
            columns: 7
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: root.cells

                Item {
                    id: cell

                    required property var modelData

                    readonly property bool inMonth: modelData.getMonth() === root.viewDate.getMonth()
                    readonly property bool isToday: root.sameDay(modelData, root.today)

                    width: root.cellWidth
                    height: 30

                    Rectangle {
                        visible: cell.isToday
                        width: 26
                        height: 26
                        radius: 13
                        color: Theme.accent
                        anchors.centerIn: parent
                    }

                    Text {
                        text: cell.modelData.getDate()
                        color: cell.isToday
                            ? Theme.background
                            : (cell.inMonth ? Theme.foreground : Theme.muted)
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                        font.bold: cell.isToday
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }
}
