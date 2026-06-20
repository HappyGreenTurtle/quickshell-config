import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: root

    Theme { id: theme }

    implicitWidth:  pillBg.implicitWidth
    implicitHeight: theme.barHeight

    property string ssid:       ""
    property int    signalPct:  0
    property int    signalBars: 0
    property string security:   ""
    property bool   connected:  false
    property bool   hovered:    false

    function pctToBars(pct) {
        if (pct >= 80) return 4
        if (pct >= 55) return 3
        if (pct >= 30) return 2
        if (pct > 0)   return 1
        return 0
    }

    // ── nmcli poll ────────────────────────────────────────────────────
    Process {
        id: nmcliProc
        
        // Using declarative target commands
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        property bool foundActive: false

        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split(":")
                if (parts.length < 4) return
                if (parts[0] === "yes") {
                    nmcliProc.foundActive = true
                    root.connected   = true
                    root.ssid        = parts[1] || "Hidden Network"
                    root.signalPct   = parseInt(parts[2], 10) || 0
                    root.signalBars  = root.pctToBars(root.signalPct)
                    root.security    = parts[3] || "Open"
                }
            }
        }
        
        onStarted: { foundActive = false }
        
        onExited: {
            if (!foundActive) {
                root.connected  = false
                root.ssid       = ""
                root.signalPct  = 0
                root.signalBars = 0
                root.security   = ""
            }
        }
    }

    Timer {
        interval: theme.netInterval || 4000
        running: true; repeat: true; triggeredOnStart: true
        
        // FIX: Toggle running status instead of explicit .start() method calls 
        // to avoid asynchronous runtime race conditions inside Quickshell's IO backend
        onTriggered: nmcliProc.running = true
    }

    readonly property string displaySsid: {
        if (!root.connected) return "offline"
        if (root.ssid.length <= 9) return root.ssid
        return root.ssid.substring(0, 8) + "…"
    }

    // ── pill ──────────────────────────────────────────────────────────
    Rectangle {
        id: pillBg
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: innerRow.implicitWidth + theme.pillPaddingH * 2
        height: 26; radius: theme.pillRadius
        color:        root.hovered ? theme.bgHover   : theme.bgSurface
        border.width: 0.5
        border.color: root.hovered ? theme.borderHover : theme.border
        Behavior on color        { ColorAnimation { duration: theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: theme.animFast } }

        Row {
            id: innerRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: theme.pillPaddingH
            spacing: 5

            Item {
                width: 13; height: 13
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: 4
                    Rectangle {
                        property int  barH: [4, 6, 9, 13][index]
                        property bool lit:  root.signalBars > index
                        width: 2.5; height: barH; radius: 1.2
                        x: index * 3.5; y: 13 - barH
                        color:   lit ? theme.archCyan : Qt.rgba(1, 1, 1, 0.15)
                        opacity: root.connected ? 1.0 : 0.25
                        Behavior on color   { ColorAnimation  { duration: theme.animMed } }
                        Behavior on opacity { NumberAnimation { duration: theme.animMed } }
                    }
                }
            }

            Text {
                id: ssidLabel
                anchors.verticalCenter: parent.verticalCenter
                text: root.displaySsid
                font.family: theme.fontFamily; font.pixelSize: theme.fontSm; font.weight: theme.weightMed
                color: root.connected ? theme.textPrimary : theme.textDim
                Behavior on color { ColorAnimation { duration: theme.animMed } }
            }
        }
    }

    // FIX: Explicitly bind the hover state change event straight to your OSD's internal engine
    HoverHandler { 
        onHoveredChanged: {
            root.hovered = hovered
            if (hovered) {
                netOsd.osdActive = true
            } else {
                netOsd.osdActive = false
            }
        } 
    }

    // ── OSD popup — same pattern as VolumeOSD ────────────────────────
    NetworkOSD {
        id: netOsd
        targetItem: pillBg
        connected:  root.connected
        ssid:       root.ssid
        signalPct:  root.signalPct
        security:   root.security
    }
}
