import Quickshell
import QtQuick
import QtQuick.Layouts
import "."

// ─────────────────────────────────────────────
//  NetworkOSD.qml
//  Mirrors VolumeOSD pattern exactly
// ─────────────────────────────────────────────

PopupWindow {
    id: osdWindow

    property var    targetItem: null
    property bool   connected:  false
    property string ssid:       ""
    property int    signalPct:  0
    property string security:   ""

    // Internal state management flag
    property bool   osdActive:  false

    color:   "transparent"
    
    // Safety unmap logic cleanly references the managed internal active flag state
    visible: osdActive || contentContainer.opacity > 0.001

    anchor {
        item:  osdWindow.targetItem
        edges: Edges.Bottom | Edges.HorizontalCenter
    }

    implicitWidth:  260
    implicitHeight: 100

    // ─────────────────────────────────────────────
    // AUTO DISMISS PIPELINE (FOR NEW CONNECTIONS)
    // ─────────────────────────────────────────────
    Timer {
        id: dismissTimer
        interval: 2200
        repeat: false
        onTriggered: osdWindow.osdActive = false
    }

    function trigger() {
        osdWindow.osdActive = true
        dismissTimer.restart()
    }

    Rectangle {
        id: contentContainer
        width:  220
        height: tipLayout.implicitHeight + 20
        radius: 14
        color:  Qt.rgba(0.06, 0.07, 0.09, 0.85)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        // Centered geometry + HorizontalOffset to nudge the element slightly right
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 15

        opacity: osdWindow.osdActive ? 1.0 : 0.0
        scale:   osdWindow.osdActive ? 1.0 : 0.93
        y:       osdWindow.osdActive ? 14  : -40

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutBack  } }
        Behavior on y       { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: tipLayout
            anchors.centerIn: parent
            spacing: 5
            width: parent.width - 24

            Text {
                Layout.alignment: Qt.AlignHCenter
                text:            osdWindow.connected ? osdWindow.ssid : "Not Connected"
                font.pixelSize:  12
                font.weight:     Font.Bold
                color:           Qt.rgba(1, 1, 1, 0.9)
                elide:           Text.ElideRight
                Layout.maximumWidth: parent.width
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                visible:         osdWindow.connected
                text:            "Signal: " + osdWindow.signalPct + "%  |  " + osdWindow.security
                font.pixelSize:  11
                color:           Qt.rgba(1, 1, 1, 0.45)
            }

            // Signal bar
            Rectangle {
                visible:             osdWindow.connected
                Layout.fillWidth:    true
                height:              5
                radius:              3
                color:               Qt.rgba(1, 1, 1, 0.08)

                Rectangle {
                    width:  parent.width * (osdWindow.signalPct / 100)
                    height: parent.height
                    radius: 3
                    color:  "#00b4d8"
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
