pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../Singleton"
import "../../../common"

Rectangle {
    id: root
    property real sf: 1.0

    implicitWidth: row.implicitWidth + Math.round(Style.spaceMd * sf) * 2
    implicitHeight: Math.round(22 * sf)
    radius: Style.radiusFull
    color: Style.bgTertiary

    property real prevRx: 0
    property real prevTx: 0
    property bool hasData: false

    property string uploadSpeed: "0 B/s"
    property string downloadSpeed: "0 B/s"

    property real rxPerSec: 0
    property real txPerSec: 0

    function formatSpeed(bytesPerSec: real): string {
        if (bytesPerSec >= 1073741824)
            return (bytesPerSec / 1073741824).toFixed(1) + " GB/s"
        if (bytesPerSec >= 1048576)
            return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
        if (bytesPerSec >= 1024)
            return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        return Math.round(bytesPerSec) + " B/s"
    }

    function speedColor(bytesPerSec) {
        if (bytesPerSec >= 10485760) return Style.accentAmber    // >10MB/s
        if (bytesPerSec >= 1048576) return Style.accentPink      // >1MB/s
        if (bytesPerSec >= 102400) return Style.accentPink       // >100KB/s
        return Style.textSecondary
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(Style.spaceSm * root.sf)

        StyledText {
            text: "↑"
            font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
            font.bold: true
            color: root.speedColor(root.txPerSec)

            Behavior on color { ColorAnimation { duration: Style.animFast } }
        }

        StyledText {
            text: root.uploadSpeed
            font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
            color: root.speedColor(root.txPerSec)

            Behavior on color { ColorAnimation { duration: Style.animFast } }
        }

        StyledText {
            text: "↓"
            font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
            font.bold: true
            color: root.speedColor(root.rxPerSec)

            Behavior on color { ColorAnimation { duration: Style.animFast } }
        }

        StyledText {
            text: root.downloadSpeed
            font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
            color: root.speedColor(root.rxPerSec)

            Behavior on color { ColorAnimation { duration: Style.animFast } }
        }
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
                    if (parts.length < 10) continue
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
