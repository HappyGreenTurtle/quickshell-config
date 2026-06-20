import Quickshell
import Quickshell.Io
import QtQuick
import "."

Item {
    id: root
    Theme { id: theme }

    implicitWidth: pillBg.implicitWidth
    implicitHeight: theme.barHeight

    property bool hovered: false

    property int currentPct: 0
    property int savedPct: 50

    property real brightnessVisual: currentPct

    readonly property bool isFullBright: currentPct >= 99
    readonly property real rayScale: 0.55 + (brightnessVisual / 100) * 0.45

    Behavior on brightnessVisual {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    onCurrentPctChanged: {
        brightnessVisual = currentPct

        osd.brightness = currentPct
        osd.trigger()
    }

    // ─────────────────────────────────────────────
    // BRIGHTNESS READER
    // ─────────────────────────────────────────────

    Process {
        id: readProc

        command: [
            "sh",
            "-c",
            "cat /sys/class/backlight/intel_backlight/brightness /sys/class/backlight/intel_backlight/max_brightness"
        ]

        property var lines: []

        stdout: SplitParser {
            onRead: (line) => {
                const t = line.trim()
                if (t.length > 0)
                    readProc.lines.push(t)
            }
        }

        onStarted: lines = []

        onExited: {
            if (lines.length < 2)
                return

            const cur = parseInt(lines[0])
            const max = parseInt(lines[1])

            if (isNaN(cur) || isNaN(max) || max <= 0)
                return

            const pct = Math.round(cur / max * 100)

            if (pct !== root.currentPct)
                root.currentPct = pct
        }
    }

    Timer {
        interval: 150
        running: true
        repeat: true

        onTriggered: {
            readProc.running = true
        }
    }

    Component.onCompleted: {
        readProc.running = true
    }

    // ─────────────────────────────────────────────
    // BRIGHTNESS SETTER
    // ─────────────────────────────────────────────

    Process {
        id: setProc
    }

    function setBrightness(pct) {
        const c = Math.max(1, Math.min(100, pct))

        root.currentPct = c

        setProc.command = [
            "brightnessctl",
            "-d",
            "intel_backlight",
            "set",
            c + "%"
        ]

        setProc.running = true
    }

    function toggleFull() {
        if (root.isFullBright) {
            setBrightness(root.savedPct > 0 ? root.savedPct : 50)
        } else {
            root.savedPct = root.currentPct
            setBrightness(100)
        }
    }

    // ─────────────────────────────────────────────
    // EXTERNAL OSD
    // ─────────────────────────────────────────────

    BrightnessOSD {
        id: osd
        targetItem: pillBg
        brightness: root.currentPct
    }

    // ─────────────────────────────────────────────
    // UI
    // ─────────────────────────────────────────────

    Rectangle {
        id: pillBg

        anchors.verticalCenter: parent.verticalCenter

        implicitWidth: row.implicitWidth + theme.pillPaddingH * 2
        height: 26
        radius: theme.pillRadius

        color: root.hovered ? theme.bgHover : theme.bgSurface

        border.width: 0.5
        border.color: root.hovered ? theme.borderHover : theme.border

        Behavior on color {
            ColorAnimation {
                duration: theme.animFast
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: theme.animFast
            }
        }

        Row {
            id: row

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: theme.pillPaddingH

            spacing: 5

            Item {
                width: 16
                height: 16

                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.centerIn: parent

                    width: 8
                    height: 8
                    radius: 4

                    color: theme.archCyan
                }

                Repeater {
                    model: 8

                    Rectangle {
                        property real rayLen: 2.5 * root.rayScale

                        anchors.centerIn: parent

                        width: 1.2
                        height: rayLen
                        radius: 0.6

                        color: theme.archCyan

                        opacity: 0.5 + (root.brightnessVisual / 100) * 0.5

                        transform: [
                            Translate { y: -5.5 },
                            Rotation {
                                origin.x: 0.6
                                origin.y: rayLen / 2
                                angle: (index / 8) * 360
                            }
                        ]

                        Behavior on height {
                            NumberAnimation {
                                duration: theme.animMed
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: theme.animMed
                            }
                        }
                    }
                }
            }

            Item {
                width: theme.miniBarWidth
                height: theme.miniBarHeight

                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: theme.miniBarRadius
                    color: Qt.rgba(1, 1, 1, 0.07)
                }

                Rectangle {
                    height: parent.height

                    width: parent.width * (root.brightnessVisual / 100)

                    radius: theme.miniBarRadius

                    color: root.currentPct < 20
                        ? theme.archDim
                        : theme.archCyan

                    Behavior on width {
                        NumberAnimation {
                            duration: theme.animMed
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: theme.animMed
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter

                text: root.currentPct + "%"

                font.family: theme.fontFamily
                font.pixelSize: theme.fontBase
                font.weight: Font.Medium

                color: root.isFullBright
                    ? theme.archCyan
                    : theme.textPrimary

                Behavior on color {
                    ColorAnimation {
                        duration: theme.animFast
                    }
                }
            }
        }
    }

    HoverHandler {
        onHoveredChanged: root.hovered = hovered
    }

    property int _stepSize: theme.brightStep ? theme.brightStep : 5

    WheelHandler {
        onWheel: (e) => {
            root.setBrightness(
                root.currentPct +
                (e.angleDelta.y > 0
                    ? root._stepSize
                    : -root._stepSize)
            )
        }
    }

    TapHandler {
        onTapped: root.toggleFull()
    }
}
