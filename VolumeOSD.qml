import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "."

PopupWindow {
    id: osdWindow

    property var targetItem: null
    color: "transparent"

    // FIX: Added matching horizontal center gravity to force symmetric expansion
    anchor {
        item: osdWindow.targetItem
        edges: (Edges.Bottom | Edges.HorizontalCenter)
        gravity: (Edges.Bottom | Edges.HorizontalCenter)
    }

    implicitWidth: 320
    implicitHeight: 140
    visible: osdVisible || contentContainer.opacity > 0.001

    // ─────────────────────────────────────────────
    // OSD STATE MANAGEMENT
    // ─────────────────────────────────────────────
    property bool osdVisible: false
    property int volume: 0
    property bool isMuted: false
    property string deviceName: "Audio Device"

    Timer {
        id: dismissTimer
        interval: 1600
        repeat: false
        onTriggered: osdWindow.osdVisible = false
    }

    function trigger() {
        osdWindow.osdVisible = true
        dismissTimer.restart()
    }

    // ─────────────────────────────────────────────
    // DESIGN: BOUGIE COLD-DARK GLASSMORPHISM
    // ─────────────────────────────────────────────
    Rectangle {
        id: contentContainer
        width: 280
        height: 64
        radius: 14
        color: Qt.rgba(0.06, 0.07, 0.09, 0.85)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        // Centers the visual panel inside the 320px popup window frame 
        // to maintain symmetric alignment with the Pill's center axis
        anchors.horizontalCenter: parent.horizontalCenter

        // Pushed the 'visible' state down to 14px (was 8px) for extra separation beneath the pill
        opacity: osdWindow.osdVisible ? 1.0 : 0.0
        scale: osdWindow.osdVisible ? 1.0 : 0.93
        y: osdWindow.osdVisible ? 14 : -40 

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: osdWindow.deviceName
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.45)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: (osdWindow.isMuted || osdWindow.volume === 0) ? "Mute" : osdWindow.volume + "%"
                    font.pixelSize: 11
                    font.bold: true
                    color: (osdWindow.isMuted || osdWindow.volume === 0) ? Qt.rgba(1, 1, 1, 0.4) : "#00f0ff"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: (osdWindow.isMuted || osdWindow.volume === 0) ? "🔇" : "🔊"
                    font.pixelSize: 14
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 5
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Rectangle {
                        width: parent.width * Math.min(1.0, osdWindow.volume / 100)
                        height: parent.height
                        radius: 3
                        color: (osdWindow.isMuted || osdWindow.volume === 0) ? Qt.rgba(1, 1, 1, 0.2) : "#00f0ff"
                    }
                }
            }
        }
    }
}
