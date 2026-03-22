import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../Singleton"
import "../../../common"

RowLayout {
    id: root
    property real sf: 1.0

    spacing: Math.round(Style.spaceMd * sf)

    property real prevRx: 0
    property real prevTx: 0
    property bool hasData: false

    property string uploadSpeed: "0 B/s"
    property string downloadSpeed: "0 B/s"

    property real rxPerSec: 0
    property real txPerSec: 0
    readonly property bool idle: rxPerSec < 1024 && txPerSec < 1024

    opacity: idle ? 0 : 1
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    function formatSpeed(bytesPerSec: real): string {
        if (bytesPerSec >= 1073741824)
            return (bytesPerSec / 1073741824).toFixed(1) + " GB/s"
        if (bytesPerSec >= 1048576)
            return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
        if (bytesPerSec >= 1024)
            return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        return Math.round(bytesPerSec) + " B/s"
    }

    StyledText {
        text: "↑"
        font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
        font.bold: true
        color: Style.accentAmber
    }

    StyledText {
        text: root.uploadSpeed
        font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
        color: Style.textSecondary
    }

    StyledText {
        text: "↓"
        font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
        font.bold: true
        color: Style.accentPink
    }

    StyledText {
        text: root.downloadSpeed
        font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
        color: Style.textSecondary
    }

    Process {
        id: netProc
        command: ["cat", "/proc/net/dev"]
        running: true

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                let lines = data.split("\n")
                let totalRx = 0
                let totalTx = 0

                for (let i = 2; i < lines.length; i++) {
                    let line = lines[i].trim()
                    if (line.length === 0) continue

                    let parts = line.split(/\s+/)
                    let iface = parts[0].replace(":", "")
                    if (iface === "lo") continue

                    totalRx += parseInt(parts[1]) || 0
                    totalTx += parseInt(parts[9]) || 0
                }

                if (root.hasData) {
                    let rxDelta = totalRx - root.prevRx
                    let txDelta = totalTx - root.prevTx

                    let rxRate = rxDelta / 2.0
                    let txRate = txDelta / 2.0

                    if (rxRate < 0) rxRate = 0
                    if (txRate < 0) txRate = 0

                    root.rxPerSec = rxRate
                    root.txPerSec = txRate
                    root.downloadSpeed = root.formatSpeed(rxRate)
                    root.uploadSpeed = root.formatSpeed(txRate)
                }

                root.prevRx = totalRx
                root.prevTx = totalTx
                root.hasData = true
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }
}
