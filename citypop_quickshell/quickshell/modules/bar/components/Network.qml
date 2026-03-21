import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../Singleton"
import "../../../common"

RowLayout {
    id: root
    property real sf: 1.0

    spacing: Math.round(Style.spaceSm * sf)

    property string connectionName: ""
    property string connectionType: ""
    readonly property bool connected: connectionName !== ""

    readonly property string iconName: {
        if (!connected) return "wifi_off"
        if (connectionType.indexOf("ethernet") >= 0) return "lan"
        if (connectionType.indexOf("wifi") >= 0) return "wifi"
        return "language"
    }

    MaterialIcon {
        text: root.iconName
        font.pixelSize: Math.round(18 * root.sf)
        color: root.connected ? Style.accentPink : Style.textDimmed
        fill: 0

        Behavior on color {
            ColorAnimation { duration: Style.animNormal }
        }
    }

    Process {
        id: nmcliProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split(":")
                if (parts.length >= 2 && parts[1] !== "loopback") {
                    root.connectionName = parts[0]
                    root.connectionType = parts[1]
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.connectionName = ""
            root.connectionType = ""
            nmcliProcess.running = true
        }
    }
}
