import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "modules"
import "."

// ─────────────────────────────────────────────
//  shell-pills.qml  –  floating pill-cluster bar
//  Place at: ~/.config/quickshell/shell-pills.qml
//  Launch:   quickshell -c shell-pills.qml
//
//  Three separate floating capsules (left / center / right)
//  instead of one continuous bar strip. Each capsule has the
//  same dark surface + rounded corners as the widget pills,
//  so the whole thing reads as "pills on pills."
// ─────────────────────────────────────────────

ShellRoot {
    Theme { id: theme }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            property var modelData
            screen:        modelData
            anchors.top:   true
            anchors.left:  true
            anchors.right: true
            height:        theme.barHeight + 14  // extra room for floating margin
            color:         "transparent"
            exclusiveZone: theme.barHeight + 6 

            // ── shared capsule style ──────────────────────────────────
            component Capsule: Rectangle {
                id: capsule
                radius: 16
                color:  theme.bgBar              // same surface color as the old full bar
                border.width: 0.5
                border.color: theme.border

                // Slide-down-and-fade entrance
                property bool show: true
                opacity: show ? 1.0 : 0.0
                y:       show ? parent.height/2 - height/2 : -(height)

                Behavior on opacity { NumberAnimation { duration: theme.animDuration; easing.type: Easing.OutCubic } }
                Behavior on y       { NumberAnimation { duration: theme.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

                Component.onCompleted: show = true

                // Top shimmer — same accent treatment as the original bar
                Rectangle {
                    anchors.top:   parent.top
                    anchors.left:  parent.left
                    anchors.right: parent.right
                    anchors.margins: parent.radius * 0.4
                    height: 1
                    radius: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: theme.archCyan }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    opacity: 0.4
                }

                // Drop shadow look via a soft border glow (no real shadow API needed)
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(0.09, 0.58, 0.82, 0.08)
                }
            }

            // ── LEFT capsule: logo + workspaces + media ───────────────
            Capsule {
                id: leftCap
                anchors.left:           parent.left
                anchors.leftMargin:     10
                anchors.verticalCenter: parent.verticalCenter
                height: theme.barHeight
                width:  leftRow.implicitWidth + 24

                Row {
                    id: leftRow
                    anchors.centerIn: parent
                    spacing: theme.gap

                    Canvas {
                        width: 22; height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        onPaint: {
                            var c = getContext("2d")
                            c.clearRect(0, 0, width, height)
                            c.beginPath(); c.moveTo(11,1); c.lineTo(21,20); c.lineTo(1,20); c.closePath()
                            c.fillStyle = "#1793d1"; c.fill()
                            c.beginPath(); c.moveTo(11,1); c.lineTo(21,20); c.lineTo(11,14); c.closePath()
                            c.fillStyle = "#00b4d8"; c.globalAlpha = 0.85; c.fill(); c.globalAlpha = 1
                            c.beginPath(); c.moveTo(11,7); c.lineTo(17,18); c.lineTo(5,18); c.closePath()
                            c.fillStyle = "#0d1117"; c.fill()
                        }
                    }

                    BarSep {}
                    Workspaces { anchors.verticalCenter: parent.verticalCenter }
                    BarSep {}
                    Media { anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // ── CENTER capsule: clock only ─────────────────────────────
            //Capsule {
            //    id: centerCap
            //    anchors.horizontalCenter: parent.horizontalCenter
            //    anchors.verticalCenter:   parent.verticalCenter
            //    height: theme.barHeight
            //    width:  centerClock.implicitWidth + 28

            //    Clock {
            //        id: centerClock
            //        anchors.centerIn: parent
            //    }
            //}

            // ── RIGHT capsule: stats + volume + brightness + battery + net
            Capsule {
                id: rightCap
                anchors.right:          parent.right
                anchors.rightMargin:    10
                anchors.verticalCenter: parent.verticalCenter
                height: theme.barHeight
                width:  rightRow.implicitWidth + 24

                Row {
                    id: rightRow
                    anchors.centerIn: parent
                    spacing: theme.gap

                    Clock {
                        id: centerClock
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    BarSep {}
                    SysStats   { anchors.verticalCenter: parent.verticalCenter }
                    BarSep {}
                    Volume     { anchors.verticalCenter: parent.verticalCenter }
                    BarSep {}
                    Brightness { anchors.verticalCenter: parent.verticalCenter }
                    Battery    { anchors.verticalCenter: parent.verticalCenter }
                    BarSep {}
                    Network    { anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }
}
