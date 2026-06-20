import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// ─────────────────────────────────────────────
//  Workspaces.qml  –  Hyprland IPC workspace pills
//  Fixed: uses Hyprland.focusedMonitor and
//  explicit workspace window-count query
// ─────────────────────────────────────────────

Item {
    id: root

    Theme { id: theme }

    property int minWorkspaces: 5

    // Active workspace id — read from focused monitor
    property int activeId: Hyprland.focusedMonitor
                           ? Hyprland.focusedMonitor.activeWorkspace.id
                           : 1

    // Build a map of occupied workspace ids from Hyprland.workspaces
    property var occupiedIds: {
        var ids = {}
        var ws = Hyprland.workspaces
        for (var i = 0; i < ws.length; i++) {
            if (ws[i].windowCount > 0) ids[ws[i].id] = true
        }
        return ids
    }

    property int highestOccupied: {
        var max = minWorkspaces
        var ws = Hyprland.workspaces
        for (var i = 0; i < ws.length; i++) {
            if (ws[i].id > max) max = ws[i].id
        }
        return max
    }

    property int visibleCount: Math.max(minWorkspaces, highestOccupied)

    implicitWidth:  wsRow.implicitWidth
    implicitHeight: theme.barHeight

    Item {
        id: container
        anchors.verticalCenter: parent.verticalCenter
        width: wsRow.width
        height: theme.wsHeight

        // ANIMATION ACCENT: Sliding background pill tracking activeId
        Rectangle {
            id: activeIndicator
            width: theme.wsWidth
            height: theme.wsHeight
            radius: theme.wsRadius
            color: Qt.rgba(0.09, 0.58, 0.82, 0.18)
            border.width: 0.5
            border.color: Qt.rgba(0.09, 0.58, 0.82, 0.55)

            // Map target model index coordinates smoothly
            x: (root.activeId - 1) * (theme.wsWidth + theme.gapSm)

            // Fluid spring slider motion definition
            Behavior on x {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }

        Row {
            id: wsRow
            spacing: theme.gapSm

            Repeater {
                model: root.visibleCount

                delegate: Item {
                    id: pill

                    property int  wsId:     index + 1
                    property bool isActive:  root.activeId === wsId
                    property bool isOccupied: root.occupiedIds[wsId] === true

                    implicitWidth:  theme.wsWidth
                    implicitHeight: theme.wsHeight

                    // Subtle background fallback container for hover highlights
                    Rectangle {
                        id: bg
                        anchors.fill: parent
                        radius: theme.wsRadius
                        color: hov.hovered && !pill.isActive ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                        border.width: 0.5
                        border.color: hov.hovered && !pill.isActive ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                        Behavior on color        { ColorAnimation { duration: theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: theme.animFast } }
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: pill.isOccupied ? -2 : 0
                        text: pill.wsId
                        font.family:    theme.fontFamily
                        font.pixelSize: theme.fontBase
                        font.weight:    pill.isActive ? theme.weightMed : theme.weightNormal
                        color: pill.isActive   ? theme.archCyan
                             : pill.isOccupied ? theme.textPrimary
                             : hov.hovered     ? theme.textPrimary
                             :                  theme.textMuted
                        Behavior on color { ColorAnimation { duration: theme.animFast } }
                    }

                    // Occupied dot indicator tracking
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 3
                        width: 4; height: 4; radius: 2
                        color:   pill.isActive ? theme.archCyan : theme.archBlue
                        opacity: pill.isOccupied ? (pill.isActive ? 0.9 : 0.55) : 0
                        Behavior on opacity { NumberAnimation { duration: theme.animMed } }
                        Behavior on color   { ColorAnimation  { duration: theme.animFast } }
                    }

                    // Scale bounce spring adjustment behavior on selection states
                    transform: Scale {
                        origin.x: pill.implicitWidth  / 2
                        origin.y: pill.implicitHeight / 2
                        xScale: pill.isActive ? 1.08 : (hov.hovered ? 1.03 : 1.0)
                        yScale: xScale
                        Behavior on xScale {
                            NumberAnimation { duration: theme.animMed; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                        }
                    }

                    HoverHandler { id: hov }
                    
                    TapHandler   { 
                        onTapped: Hyprland.dispatch("hl.dsp.focus({ workspace = " + pill.wsId + " })") 
                    }
                    WheelHandler {
                        onWheel: (e) => {
                            if (e.angleDelta.y > 0) {
                                Hyprland.dispatch("hl.dsp.focus({ workspace = 'e-1' })")
                            } else {
                                Hyprland.dispatch("hl.dsp.focus({ workspace = 'e+1' })")
                            }
                        }
                    }
                }
            }
        }
    }
}
