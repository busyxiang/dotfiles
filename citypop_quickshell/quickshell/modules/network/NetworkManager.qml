pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool panelVisible: false
    property var panelScreen: null

    property string connectionName: ""
    property string connectionType: ""
    readonly property bool connected: connectionName !== ""

    property list<var> networks: []
    property list<var> knownConnections: []
    property bool scanning: false
    property string connectingTo: ""
    property string connectError: ""

    readonly property string iconName: {
        if (!connected) return "wifi_off"
        if (connectionType.indexOf("ethernet") >= 0 || connectionType.indexOf("wired") >= 0) return "lan"
        if (connectionType.indexOf("wifi") >= 0 || connectionType.indexOf("wireless") >= 0) return "wifi"
        return "language"
    }

    function togglePanel() {
        panelVisible = !panelVisible
        if (panelVisible) {
            initialLoaded = false
            scan()
        }
    }

    property bool initialLoaded: false

    function scan() {
        scanning = true
        scanBuffer = []
        scanProc.running = true
    }

    property list<var> scanBuffer: []

    function connectToNetwork(ssid, password) {
        connectingTo = ssid
        connectError = ""
        if (password)
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password]
        else
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid]
        connectProc.running = true
    }

    function disconnect() {
        disconnectProc.running = true
    }

    // Poll active connection
    Process {
        id: statusProc
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
            statusProc.running = true
        }
    }

    // Auto-refresh while panel is open (waits for initial load)
    Timer {
        interval: 5000
        running: root.panelVisible && !root.scanning && root.initialLoaded
        repeat: true
        onTriggered: root.scan()
    }

    // Scan wifi networks — buffer results, swap on completion
    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.split(":")
                if (parts.length >= 4 && parts[0] !== "") {
                    var existing = root.scanBuffer.find(n => n.ssid === parts[0])
                    if (existing) {
                        if (parseInt(parts[1]) > existing.signal) {
                            existing.signal = parseInt(parts[1])
                            existing.inUse = parts[3] === "*"
                        }
                    } else {
                        root.scanBuffer.push({
                            ssid: parts[0],
                            signal: parseInt(parts[1]),
                            security: parts[2],
                            inUse: parts[3] === "*"
                        })
                    }
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                root.scanning = false
                root.initialLoaded = true
                // Sort and swap in one go
                root.scanBuffer.sort((a, b) => b.signal - a.signal)
                root.networks = root.scanBuffer
                knownProc.running = true
            }
        }
    }

    // Get known connections
    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.split(":")
                if (parts.length >= 2 && parts[1].indexOf("wireless") >= 0) {
                    var copy = root.knownConnections.slice()
                    copy.push(parts[0])
                    root.knownConnections = copy
                }
            }
        }
        onRunningChanged: {
            if (running) root.knownConnections = []
        }
    }

    // Connect to network
    Process {
        id: connectProc
        stderr: SplitParser {
            onRead: data => {
                root.connectError = data
            }
        }
        onRunningChanged: {
            if (!running) {
                root.connectingTo = ""
                // Refresh status
                root.connectionName = ""
                root.connectionType = ""
                statusProc.running = true
                // Re-scan to update in-use
                if (root.panelVisible) scan()
            }
        }
    }

    // Disconnect
    Process {
        id: disconnectProc
        command: ["nmcli", "connection", "down", root.connectionName]
        onRunningChanged: {
            if (!running) {
                root.connectionName = ""
                root.connectionType = ""
                statusProc.running = true
                if (root.panelVisible) scan()
            }
        }
    }
}
