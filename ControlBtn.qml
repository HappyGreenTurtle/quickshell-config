import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import ".."
import "."
// ─────────────────────────────────────────────
//  ControlBtn  –  reusable media control button
// ─────────────────────────────────────────────
Item {
    id: btn

    required property string iconChar
    signal clicked()

    property bool pressed: false

    Theme { id: theme }

    implicitWidth:  22
    implicitHeight: 22

    Rectangle {
        anchors.centerIn: parent
        width:  18
        height: 18
        radius: 4
        color:  btnHov.hovered
                ? Qt.rgba(0.09, 0.58, 0.82, 0.18)
                : "transparent"

        Behavior on color { ColorAnimation { duration: theme.animFast } }

        Text {
            anchors.centerIn: parent
            text:           btn.iconChar
            font.pixelSize: 10
            color:          btnHov.hovered
                            ? theme.archCyan
                            : theme.textMuted

            Behavior on color { ColorAnimation { duration: theme.animFast } }
        }
    }

    HoverHandler  { id: btnHov }

    TapHandler {
 //       onPressed:  btn.pressed = true
 //       onClicked: btn.pressed = false
        onPressedChanged: btn.pressed = pressed
        onTapped:   btn.clicked()
    }
}
