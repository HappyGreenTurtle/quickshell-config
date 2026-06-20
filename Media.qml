import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: root
    Theme { id: theme }

    implicitHeight: (theme && theme.barHeight !== undefined) ? theme.barHeight : 26
    implicitWidth: shouldShow ? pillBg.implicitWidth : 0

    property bool hovered: false
    property bool osdHovered: false
    property bool osdOpen: false
    property bool pausedHold: false

    readonly property var playerList: Mpris.players.values

    readonly property MprisPlayer activePlayer: {
        if (!playerList || playerList.length === 0)
            return null

        for (let i = 0; i < playerList.length; ++i) {
            const p = playerList[i]
            if (p && p.isPlaying)
                return p
        }

        return playerList[0]
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
    readonly property bool shouldShow: hasPlayer && (isPlaying || pausedHold || osdOpen)

    readonly property string trackTitle:
        activePlayer ? (activePlayer.trackTitle || "Unknown Title") : ""

    readonly property string trackArtist:
        activePlayer ? (activePlayer.trackArtist || "Unknown Artist") : ""

    readonly property string trackAlbum:
        activePlayer ? (activePlayer.trackAlbum || "") : ""

    readonly property string playerIdentity:
        activePlayer ? (activePlayer.identity || "") : ""

    readonly property string artUrl:
        activePlayer ? (activePlayer.trackArtUrl || "") : ""

    readonly property real trackPosition:
        activePlayer ? activePlayer.position : 0

    readonly property real trackLength:
        activePlayer ? activePlayer.length : 0

    readonly property real progress:
        (trackLength > 0) ? Math.max(0, Math.min(1, trackPosition / trackLength)) : 0

    readonly property bool canSeek:
        activePlayer ? (activePlayer.canSeek && activePlayer.positionSupported) : false

    readonly property string displayText: {
        if (!activePlayer)
            return ""

        if (trackArtist.length > 0)
            return trackArtist + " — " + trackTitle

        return trackTitle
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0 || !isFinite(seconds))
            return "0:00"

        const total = Math.floor(seconds)
        const mins = Math.floor(total / 60)
        const secs = total % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    function openOsd() {
        if (!shouldShow)
            return

        osdOpen = true
        hideOsdTimer.stop()
        mediaOsd.open()
    }

    function closeOsd() {
        osdOpen = false
        hideOsdTimer.stop()
        mediaOsd.close()
    }

    function scheduleOsdHide() {
        if (!osdHovered && !hovered)
            hideOsdTimer.restart()
    }

    Timer {
        id: pauseHideTimer
        interval: 60000
        repeat: false
        onTriggered: {
            root.pausedHold = false
            if (!root.hovered && !root.osdHovered)
                root.closeOsd()
        }
    }

    Timer {
        id: hideOsdTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (!root.hovered && !root.osdHovered)
                root.closeOsd()
        }
    }

    Timer {
        id: progressTimer
        interval: 250
        repeat: true
        running: root.activePlayer && root.activePlayer.isPlaying && !mediaOsd.scrubbing
        onTriggered: {
            if (root.activePlayer)
                root.activePlayer.positionChanged()
        }
    }

    onActivePlayerChanged: {
        pausedHold = false
        pauseHideTimer.stop()
    }

    onIsPlayingChanged: {
        if (isPlaying) {
            pausedHold = false
            pauseHideTimer.stop()
        } else if (hasPlayer) {
            pausedHold = true
            pauseHideTimer.restart()
        } else {
            pausedHold = false
            pauseHideTimer.stop()
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: (theme && theme.animMed !== undefined) ? theme.animMed : 200
            easing.type: Easing.OutCubic
        }
    }

    opacity: shouldShow ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: pillBg

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: row.implicitWidth + (((theme && theme.pillPaddingH !== undefined) ? theme.pillPaddingH : 10) * 2)
        height: 26
        radius: (theme && theme.pillRadius !== undefined) ? theme.pillRadius : 13

        color: root.hovered
               ? ((theme && theme.bgHover !== undefined) ? theme.bgHover : "#2a2a2a")
               : ((theme && theme.bgSurface !== undefined) ? theme.bgSurface : "#1e1e1e")

        border.width: 0.5
        border.color: root.hovered
                      ? ((theme && theme.borderHover !== undefined) ? theme.borderHover : "#666666")
                      : ((theme && theme.border !== undefined) ? theme.border : "#444444")

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: (theme && theme.pillPaddingH !== undefined) ? theme.pillPaddingH : 10
            spacing: 6

            Text {
                text: isPlaying ? "♪" : "⏸"
                color: isPlaying
                       ? ((theme && theme.archCyan !== undefined) ? theme.archCyan : "#4cc9f0")
                       : ((theme && theme.textMuted !== undefined) ? theme.textMuted : "#999999")
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: displayText
                font.family: (theme && theme.fontFamily !== undefined) ? theme.fontFamily : "Sans Serif"
                font.pixelSize: (theme && theme.fontBase !== undefined) ? theme.fontBase : 12
                color: (theme && theme.textPrimary !== undefined) ? theme.textPrimary : "#ffffff"
                elide: Text.ElideRight
                width: 220
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        HoverHandler {
            onHoveredChanged: {
                root.hovered = hovered

                if (hovered && root.shouldShow)
                    root.openOsd()
                else
                    root.scheduleOsdHide()
            }
        }

        TapHandler {
            onTapped: {
                if (!root.shouldShow)
                    return

                if (root.osdOpen)
                    root.closeOsd()
                else
                    root.openOsd()
            }
        }
    }

    MediaOSD {
        id: mediaOsd
        targetItem: pillBg

        title: trackTitle
        artist: trackArtist
        album: trackAlbum
        playerIdentity: playerIdentity
        artUrl: artUrl

        isPlaying: root.isPlaying
        progress: root.progress
        positionText: root.formatTime(scrubbing ? scrubPosition : root.trackPosition)
        lengthText: root.formatTime(root.trackLength)

        canGoPrevious: root.activePlayer ? root.activePlayer.canGoPrevious : false
        canTogglePlaying: root.activePlayer ? root.activePlayer.canTogglePlaying : false
        canGoNext: root.activePlayer ? root.activePlayer.canGoNext : false
        canSeek: root.canSeek
        duration: root.trackLength

        onHoveredChanged: function(hovered) {
            root.osdHovered = hovered
            if (hovered) {
                hideOsdTimer.stop()
                root.osdOpen = true
            } else {
                root.scheduleOsdHide()
            }
        }

        onPreviousRequested: if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous()
        onToggleRequested: if (root.activePlayer && root.activePlayer.canTogglePlaying) root.activePlayer.togglePlaying()
        onNextRequested: if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next()

        onSeekRequested: function(seconds) {
            if (!root.activePlayer || !root.canSeek)
                return

            const clamped = Math.max(0, Math.min(root.trackLength, seconds))

            root.activePlayer.position = clamped
            root.activePlayer.positionChanged()
        }
    }
}
