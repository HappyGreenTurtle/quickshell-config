import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "."

Item {
    id: root
    Theme { id: theme }

    implicitWidth: pillBg.implicitWidth
    implicitHeight: theme.barHeight

    property bool hovered: false

    // ─────────────────────────────────────────────
    // NATIVE CORE PIPEWIRE EVENT BINDINGS
    // ─────────────────────────────────────────────
    PwObjectTracker {
        id: sinkTracker
        objects: [ Pipewire.defaultAudioSink ]
    }

    readonly property var sink: Pipewire.defaultAudioSink

    property int volumePct: (sink && sink.audio) ? Math.round(sink.audio.volume * 100) : 0
    property bool muted: (sink && sink.audio) ? sink.audio.muted : false
    property string deviceName: sink ? sink.description : "Audio"

    // ─────────────────────────────────────────────
    // RELIABLE OSD EVENT PIPELINE
    // ─────────────────────────────────────────────
    onVolumePctChanged: {
        volumeVisual = volumePct
        popup.volume = volumePct
        popup.trigger()
    }

    onMutedChanged: {
        popup.isMuted = muted
        popup.trigger()
    }

    onDeviceNameChanged: {
        popup.deviceName = deviceName
        popup.trigger()
    }

    // Instantiated child popup element
    VolumeOSD {
        id: popup
        volume: root.volumePct
        isMuted: root.muted
        deviceName: root.deviceName
        
        // FIX: Directly pass the pill layout element token context to dock below it
        targetItem: pillBg
    }

    // ─────────────────────────────────────────────
    // JITTER-FREE VISUAL INTERPOLATION
    // ─────────────────────────────────────────────
    property real volumeVisual: 0

    Behavior on volumeVisual {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    readonly property color barColor:
        (muted || volumePct === 0) ? theme.textDim : volumePct > 100 ? theme.warning : theme.archCyan

    // ─────────────────────────────────────────────
    // DRIVER SETTERS
    // ─────────────────────────────────────────────
    function setVol(pct) {
        if (!sink || !sink.audio) return
        var c = Math.max(0, Math.min(150, pct))
        sink.audio.volume = c / 100
    }

    function toggleMute() {
        if (!sink || !sink.audio) return
        sink.audio.muted = !sink.audio.muted
    }

    // ─────────────────────────────────────────────
    // PRIMARY STATUS BAR MODULE WIDGET
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

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: theme.pillPaddingH
            spacing: 5

            Text {
                text: (root.muted || root.volumePct === 0) ? "🔇" : root.volumePct < 50 ? "🔉" : "🔊"
                font.pixelSize: 13
                color: (root.muted || root.volumePct === 0) ? theme.textDim : theme.archCyan
            }

            Item {
                width: theme.miniBarWidth
                height: theme.miniBarHeight
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: theme.miniBarRadius
                    color: Qt.rgba(1,1,1,0.07)
                }

                Rectangle {
                    height: parent.height
                    width: parent.width * Math.min(1.0, root.volumeVisual / 100)
                    radius: theme.miniBarRadius
                    color: root.barColor
                    opacity: (root.muted || root.volumePct === 0) ? 0.3 : 1.0
                }
            }

            Text {
                text: (root.muted || root.volumePct === 0) ? "mute" : root.volumePct + "%"
                font.family: theme.fontFamily
                font.pixelSize: theme.fontBase
                color: (root.muted || root.volumePct === 0) ? theme.textDim : theme.textPrimary
            }
        }
    }

    HoverHandler { onHoveredChanged: root.hovered = hovered }
    WheelHandler { onWheel: (e) => root.setVol(root.volumePct + (e.angleDelta.y > 0 ? 5 : -5)) }
    TapHandler { onTapped: root.toggleMute() }
}
