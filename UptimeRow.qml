import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: upr
    Theme { id: theme }

    implicitHeight: 16
    implicitWidth: parent ? parent.width : 200

    property string uptimeStr: "…"

    // ── Timer ───────────────────────────────────────────────
    Timer {
        id: updateTimer
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            // FIX: no .start() in your Quickshell version
            uptimeProc.command = uptimeProc.command
        }
    }

    // ── Process ─────────────────────────────────────────────
    Process {
        id: uptimeProc
        command: ["sh", "-c", "cat /proc/uptime"]

        stdout: SplitParser {
            onRead: (line) => {
                var cleanLine = line.trim()
                if (!cleanLine) return

                var parts = cleanLine.split(" ")
                if (parts.length < 1) return

                var secs = Math.floor(parseFloat(parts[0]))
                if (isNaN(secs)) return

                var h = Math.floor(secs / 3600)
                var m = Math.floor((secs % 3600) / 60)

                upr.uptimeStr = h + "h " + m + "m"
            }
        }
    }

    // ── UI ───────────────────────────────────────────────────
    Row {
        width: parent.width
        spacing: 0

        Text {
            text: "Uptime"
            font.family: theme.fontFamily
            font.pixelSize: 10
            color: theme.textMuted
            width: 60
        }

        Text {
            text: upr.uptimeStr
            font.family: theme.fontFamily
            font.pixelSize: 10
            color: theme.textPrimary
        }
    }
}
