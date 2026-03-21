import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../Singleton"
import "../../../common"

RowLayout {
    id: root
    property real sf: 1.0

    spacing: Math.round(Style.spaceSm * sf)

    property string layout: "en"

    MaterialIcon {
        text: "keyboard"
        font.pixelSize: Math.round(16 * root.sf)
        color: Style.accentPink
        fill: 0
    }

    StyledText {
        text: root.layout.toUpperCase()
        font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
        color: Style.textSecondary
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            switchProc.running = true
        }
    }

    Process {
        id: queryProc
        command: ["hyprctl", "devices", "-j"]
        running: true

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var devices = JSON.parse(data)
                    var keyboards = devices.keyboards
                    if (keyboards && keyboards.length > 0) {
                        var kb = keyboards[keyboards.length - 1]
                        var lang = kb.active_keymap || ""
                        if (lang.indexOf("English") >= 0) root.layout = "en"
                        else if (lang.indexOf("Japanese") >= 0) root.layout = "jp"
                        else if (lang.indexOf("Korean") >= 0) root.layout = "ko"
                        else root.layout = lang.substring(0, 2).toLowerCase()
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: switchProc
        command: ["hyprctl", "switchxkblayout", "all", "next"]

        onExited: (exitCode, exitStatus) => {
            queryProc.running = true
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: queryProc.running = true
    }
}
