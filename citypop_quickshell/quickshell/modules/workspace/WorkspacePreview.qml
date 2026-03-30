pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../Singleton"

Singleton {
    id: root

    property bool tooltipVisible: false
    property var tooltipScreen: null
    property real tooltipX: 0
    property int hoveredWsId: -1

    // Preview data
    property var previewClients: []  // [{ x, y, w, h, cls, icon }]
    property real monitorW: 0
    property real monitorH: 0

    function show(): void {
        hideTimer.stop()
        tooltipVisible = true
        if (!monitorsProc.running && !clientsProc.running)
            monitorsProc.running = true
    }

    function hide(): void {
        hideTimer.start()
    }

    Timer {
        id: hideTimer
        interval: 200
        onTriggered: root.tooltipVisible = false
    }

    // Fetch monitors first, then clients
    property var _monitors: ({})  // id -> { x, y, width, height }

    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "-j"]
        property string _buf: ""
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { monitorsProc._buf = data }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && monitorsProc._buf.length > 0) {
                try {
                    var mons = JSON.parse(monitorsProc._buf)
                    var map = {}
                    for (var i = 0; i < mons.length; i++) {
                        map[mons[i].id] = {
                            x: mons[i].x, y: mons[i].y,
                            width: mons[i].width, height: mons[i].height
                        }
                    }
                    root._monitors = map
                } catch (e) {}
            }
            monitorsProc._buf = ""
            clientsProc.running = true
        }
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        property string _buf: ""
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { clientsProc._buf = data }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || clientsProc._buf.length === 0) {
                clientsProc._buf = ""
                return
            }
            try {
                var all = JSON.parse(clientsProc._buf)
                var wsId = root.hoveredWsId
                var clients = []
                for (var i = 0; i < all.length; i++) {
                    var c = all[i]
                    if (c.workspace.id !== wsId || !c.mapped || c.hidden) continue

                    var mon = root._monitors[c.monitor]
                    if (mon) {
                        root.monitorW = mon.width
                        root.monitorH = mon.height
                    }
                    var monX = mon ? mon.x : 0
                    var monY = mon ? mon.y : 0

                    var entry = DesktopEntries.byId(c.class) ?? DesktopEntries.heuristicLookup(c.class)
                    clients.push({
                        x: c.at[0] - monX,
                        y: c.at[1] - monY,
                        w: c.size[0],
                        h: c.size[1],
                        cls: c.class,
                        icon: (entry && entry.icon) ? Quickshell.iconPath(entry.icon) : ""
                    })
                }
                root.previewClients = clients
            } catch (e) { /* parse error */ }
            clientsProc._buf = ""
        }
    }
}
