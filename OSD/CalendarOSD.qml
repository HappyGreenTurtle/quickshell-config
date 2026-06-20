import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

// CalendarOSD.qml — PopupWindow calendar, mirrors VolumeOSD pattern
PopupWindow {
    id: osdWindow

    property var targetItem: null
    property bool calVisible: false

    color:   "transparent"
    visible: calVisible || container.opacity > 0.001

    anchor {
        item:  osdWindow.targetItem
        edges: Edges.Bottom | Edges.HorizontalCenter
        gravity: Edges.Bottom | Edges.HorizontalCenter
    }

    implicitWidth:  240
    implicitHeight: 300

    function toggle() { calVisible = !calVisible }
    function close()  { calVisible = false }

    // FIX: Replaced the tricky window TapHandler with a fallback MouseArea backdrop.
    // It filters out clicks that land inside the actual calendar bounds, preventing accidental dismissals.
    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => {
            // Check if the click coordinates fall outside the main container frame
            var containerPoint = mapToItem(container, mouse.x, mouse.y);
            if (!container.contains(containerPoint)) {
                osdWindow.close();
            } else {
                // Forwards mouse events safely to the child buttons inside the box
                mouse.accepted = false;
            }
        }
    }

    Rectangle {
        id: container
        width:  220
        radius: 14
        color:  Qt.rgba(0.06, 0.07, 0.09, 0.92)
        border.width: 1
        border.color: Qt.rgba(0.09, 0.58, 0.82, 0.35)

        anchors.horizontalCenter: parent.horizontalCenter

        opacity: osdWindow.calVisible ? 1.0 : 0.0
        scale:   osdWindow.calVisible ? 1.0 : 0.93
        y:       osdWindow.calVisible ? 14   : -40

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack  } }
        Behavior on y       { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // Height follows content
        height: innerCol.implicitHeight + 24

        Column {
            id: innerCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10

            // ── Month navigation ──────────────────────────────────────
            property int viewYear:  new Date().getFullYear()
            property int viewMonth: new Date().getMonth()

            // Today's actual values for highlighting
            property int todayYear:  new Date().getFullYear()
            property int todayMonth: new Date().getMonth()
            property int todayDate:  new Date().getDate()

            // Month names
            property var monthNames: [
                "January","February","March","April","May","June",
                "July","August","September","October","November","December"
            ]

            RowLayout {
                width: parent.width

                // Prev month button
                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: prevHov.hovered ? Qt.rgba(0.09,0.58,0.82,0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 14; color: "#7d8590" }
                    HoverHandler { id: prevHov }
                    TapHandler {
                        onTapped: {
                            if (innerCol.viewMonth === 0) {
                                innerCol.viewMonth = 11
                                innerCol.viewYear--
                            } else {
                                innerCol.viewMonth--
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: innerCol.monthNames[innerCol.viewMonth] + "  " + innerCol.viewYear
                    font.pixelSize: 12; font.weight: Font.Medium
                    color: "#00b4d8"
                }

                // Next month button
                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: nextHov.hovered ? Qt.rgba(0.09,0.58,0.82,0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 14; color: "#7d8590" }
                    HoverHandler { id: nextHov }
                    TapHandler {
                        onTapped: {
                            if (innerCol.viewMonth === 11) {
                                innerCol.viewMonth = 0
                                innerCol.viewYear++
                            } else {
                                innerCol.viewMonth++
                            }
                        }
                    }
                }
            }

            // ── Day-of-week headers ───────────────────────────────────
            Row {
                width: parent.width; spacing: 0
                Repeater {
                    model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                    Text {
                        text: modelData
                        width: (container.width - 28) / 7
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 9
                        color: (index >= 5) ? "#1793d1" : "#484f58"   // weekend tint
                    }
                }
            }

            // ── Calendar grid ─────────────────────────────────────────
            Grid {
                id: calGrid
                columns: 7
                spacing: 1
                width: parent.width

                property int year:  innerCol.viewYear
                property int month: innerCol.viewMonth

                property int firstDow: {
                    var fd = new Date(year, month, 1).getDay()
                    return (fd + 6) % 7   // Mon=0 … Sun=6
                }
                property int daysInMonth: new Date(year, month + 1, 0).getDate()
                property int totalCells:  firstDow + daysInMonth

                Repeater {
                    model: Math.ceil(calGrid.totalCells / 7) * 7

                    Rectangle {
                        property int  dayNum:  index - calGrid.firstDow + 1
                        property bool valid:   dayNum >= 1 && dayNum <= calGrid.daysInMonth
                        property bool isToday: valid
                                               && dayNum === innerCol.todayDate
                                               && calGrid.month === innerCol.todayMonth
                                               && calGrid.year  === innerCol.todayYear
                        property bool isWeekend: (index % 7) >= 5

                        width:  (container.width - 28) / 7
                        height: 22
                        radius: 5

                        color: isToday
                               ? Qt.rgba(0.09, 0.58, 0.82, 0.28)
                               : dayHov.hovered && valid
                                 ? Qt.rgba(1, 1, 1, 0.05)
                                 : "transparent"

                        border.width: isToday ? 0.5 : 0
                        border.color: isToday ? "#1793d1" : "transparent"

                        Behavior on color { ColorAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text:  valid ? dayNum : ""
                            font.pixelSize: 10
                            font.weight: isToday ? Font.Medium : Font.Normal
                            color: isToday   ? "#00b4d8"
                                 : !valid    ? "transparent"
                                 : isWeekend ? "#1793d1"
                                 :             "#e6edf3"
                        }

                        HoverHandler { id: dayHov }
                    }
                }
            }

            // ── Divider ───────────────────────────────────────────────
            Rectangle { width: parent.width; height: 0.5; color: Qt.rgba(0.09,0.58,0.82,0.2) }

            // ── Today label ───────────────────────────────────────────
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                property var d: new Date()
                property var days: ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
                property var mons: ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
                text: days[d.getDay()] + ",  " + d.getDate() + " " + mons[d.getMonth()] + " " + d.getFullYear()
                font.pixelSize: 10; color: "#7d8590"
            }
        }
    }
}
