import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "."
import "modules"
import "OSD"

ShellRoot {
    Theme { id: theme }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            property var modelData

            screen: modelData
            anchors.top: true
            anchors.left: true
            anchors.right: true

            implicitHeight: theme.barHeight

            color: "transparent"
            exclusiveZone: implicitHeight

            Rectangle {
                id: barSurface
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                height: parent.height
                color: theme.bgBar
                radius: theme.barRadius

                opacity: 0.0
                Component.onCompleted: slideIn.start()

                NumberAnimation {
                    id: slideIn
                    target: barSurface
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: theme.animDuration
                    easing.type: Easing.OutCubic
                }

                // Top shimmer line
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.25; color: theme.archBlue }
                        GradientStop { position: 0.6; color: theme.archCyan }
                        GradientStop { position: 1.0; color: "transparent" }
                    }

                    opacity: 0.55
                }

                // Bottom border
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: theme.border
                }

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: theme.barPadding
                    anchors.rightMargin: theme.barPadding

                    // LEFT
                    Row {
                        id: leftSection
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: theme.gap

                        Canvas {
                            width: 22
                            height: 22
                            anchors.verticalCenter: parent.verticalCenter

                            onPaint: {
                                var c = getContext("2d")
                                c.clearRect(0, 0, width, height)

                                c.beginPath()
                                c.moveTo(11, 1)
                                c.lineTo(21, 20)
                                c.lineTo(1, 20)
                                c.closePath()
                                c.fillStyle = "#1793d1"
                                c.fill()

                                c.beginPath()
                                c.moveTo(11, 1)
                                c.lineTo(21, 20)
                                c.lineTo(11, 14)
                                c.closePath()
                                c.fillStyle = "#00b4d8"
                                c.globalAlpha = 0.85
                                c.fill()
                                c.globalAlpha = 1.0

                                c.beginPath()
                                c.moveTo(11, 7)
                                c.lineTo(17, 18)
                                c.lineTo(5, 18)
                                c.closePath()
                                c.fillStyle = "#0d1117"
                                c.fill()
                            }
                        }

                        BarSep {}
                        Workspaces { anchors.verticalCenter: parent.verticalCenter }
                        BarSep {}
                        Media { anchors.verticalCenter: parent.verticalCenter }
                    }

                    // CENTER
                    Clock {
                        anchors.centerIn: parent
                    }

                    // RIGHT
                    Row {
                        id: rightSection
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: theme.gap

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
}
