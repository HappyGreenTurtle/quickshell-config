import Quickshell
import QtQuick
import QtQuick.Layouts
import "."

PopupWindow {
    id: osdWindow

    property var targetItem: null

    property string title: ""
    property string artist: ""
    property string album: ""
    property string playerIdentity: ""
    property string artUrl: ""

    property bool isPlaying: false
    property real progress: 0.0
    property string positionText: "0:00"
    property string lengthText: "0:00"

    property bool canGoPrevious: false
    property bool canTogglePlaying: false
    property bool canGoNext: false
    property bool canSeek: false
    property real duration: 0

    property bool scrubbing: false
    property real scrubProgress: 0.0
    property real scrubPosition: 0.0

    property int playOffsetX: 1
    property int playOffsetY: -1
    property int pauseOffsetX: 0
    property int pauseOffsetY: -1

    property bool osdVisible: false

    signal previousRequested()
    signal toggleRequested()
    signal nextRequested()
    signal seekRequested(real seconds)
    signal hoveredChanged(bool hovered)

    readonly property bool osdVisibleEffective: osdVisible || contentContainer.opacity > 0.001
    readonly property real shownProgress: scrubbing ? scrubProgress : progress

    color: "transparent"
    implicitWidth: 332
    implicitHeight: 200
    visible: osdVisibleEffective

    anchor {
        item: osdWindow.targetItem
        edges: (Edges.Bottom | Edges.HorizontalCenter)
        gravity: (Edges.Bottom | Edges.HorizontalCenter)
    }

    onProgressChanged: {
        if (!scrubbing) {
            scrubProgress = Math.max(0, Math.min(1, progress))
            scrubPosition = scrubProgress * duration
        }
    }

    onDurationChanged: {
        if (!scrubbing) {
            scrubProgress = Math.max(0, Math.min(1, progress))
            scrubPosition = scrubProgress * duration
        }
    }

    function open() {
        osdVisible = true
    }

    function close() {
        scrubbing = false
        osdVisible = false
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0 || !isFinite(seconds))
            return "0:00"

        const total = Math.floor(seconds)
        const mins = Math.floor(total / 60)
        const secs = total % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    Rectangle {
        id: contentContainer
        width: 300
        height: 150
        radius: 14
        color: Qt.rgba(0.06, 0.07, 0.09, 0.88)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        anchors.horizontalCenter: parent.horizontalCenter

        opacity: osdWindow.osdVisible ? 1.0 : 0.0
        scale: osdWindow.osdVisible ? 1.0 : 0.94
        y: osdWindow.osdVisible ? 14 : -28

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            onHoveredChanged: osdWindow.hoveredChanged(hovered)
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 60
                radius: 10
                color: "#222222"
                clip: true

                Image {
                    anchors.fill: parent
                    source: artUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: artUrl !== ""
                    asynchronous: true
                    cache: true
                }

                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: "#888888"
                    visible: artUrl === ""
                    font.pixelSize: 20
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                Text {
                    text: title || "Nothing playing"
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: artist
                    color: "#cfcfcf"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    visible: artist !== ""
                    Layout.fillWidth: true
                }

                Text {
                    text: album !== "" ? album + (playerIdentity !== "" ? " • " + playerIdentity : "") : playerIdentity
                    color: "#8f8f8f"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    visible: album !== "" || playerIdentity !== ""
                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillHeight: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Item {
                        id: scrubber
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18

                        function clamp01(v) {
                            return Math.max(0, Math.min(1, v))
                        }

                        function ratioFromMouse(mouse) {
                            const p = scrubArea.mapToItem(trackBg, mouse.x, mouse.y)
                            return clamp01(p.x / Math.max(1, trackBg.width))
                        }

                        function setFromMouse(mouse) {
                            const ratio = ratioFromMouse(mouse)
                            osdWindow.scrubProgress = ratio
                            osdWindow.scrubPosition = ratio * osdWindow.duration
                        }

                        Rectangle {
                            id: trackBg
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 5
                            radius: 2.5
                            color: "#2a2a2a"
                        }

                        Rectangle {
                            id: trackFill
                            anchors.left: trackBg.left
                            anchors.verticalCenter: trackBg.verticalCenter
                            width: trackBg.width * scrubber.clamp01(osdWindow.shownProgress)
                            height: trackBg.height
                            radius: trackBg.radius
                            color: "#4cc9f0"
                        }

                        Rectangle {
                            id: scrubHandle
                            width: 10
                            height: 10
                            radius: 5
                            color: canSeek ? "#ffffff" : "#707070"
                            border.width: 1
                            border.color: "#111111"
                            visible: canSeek
                            anchors.verticalCenter: trackBg.verticalCenter
                            x: Math.max(
                                   trackBg.x,
                                   Math.min(
                                       trackBg.x + trackBg.width - width,
                                       trackBg.x + trackBg.width * scrubber.clamp01(osdWindow.shownProgress) - width / 2
                                   )
                               )
                        }

                        MouseArea {
                            id: scrubArea
                            anchors.fill: parent
                            enabled: canSeek && duration > 0
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                            onPressed: function(mouse) {
                                osdWindow.scrubbing = true
                                scrubber.setFromMouse(mouse)
                            }

                            onPositionChanged: function(mouse) {
                                if (pressed)
                                    scrubber.setFromMouse(mouse)
                            }

                            onReleased: function(mouse) {
                                if (!osdWindow.scrubbing)
                                    return

                                scrubber.setFromMouse(mouse)
                                osdWindow.seekRequested(osdWindow.scrubPosition)
                                osdWindow.scrubbing = false
                            }

                            onCanceled: {
                                osdWindow.scrubbing = false
                                osdWindow.scrubProgress = Math.max(0, Math.min(1, osdWindow.progress))
                                osdWindow.scrubPosition = osdWindow.scrubProgress * osdWindow.duration
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: osdWindow.scrubbing ? osdWindow.formatTime(osdWindow.scrubPosition) : positionText
                            color: "#9a9a9a"
                            font.pixelSize: 9
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: lengthText
                            color: "#9a9a9a"
                            font.pixelSize: 9
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: canGoPrevious ? "#252525" : "#1a1a1a"
                        opacity: canGoPrevious ? 1.0 : 0.5

                        Text {
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "⏮"
                            color: "#ffffff"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: canGoPrevious
                            onClicked: osdWindow.previousRequested()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 19
                        color: canTogglePlaying ? "#4cc9f0" : "#1a1a1a"
                        opacity: canTogglePlaying ? 1.0 : 0.5

                        Text {
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            lineHeight: 1.0
                            text: isPlaying ? "⏸" : "▶"
                            color: canTogglePlaying ? "#111111" : "#888888"
                            font.pixelSize: 14
                            font.bold: true
                            anchors.horizontalCenterOffset: isPlaying ? pauseOffsetX : playOffsetX
                            anchors.verticalCenterOffset: isPlaying ? pauseOffsetY : playOffsetY
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: canTogglePlaying
                            onClicked: osdWindow.toggleRequested()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: canGoNext ? "#252525" : "#1a1a1a"
                        opacity: canGoNext ? 1.0 : 0.5

                        Text {
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "⏭"
                            color: "#ffffff"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: canGoNext
                            onClicked: osdWindow.nextRequested()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
