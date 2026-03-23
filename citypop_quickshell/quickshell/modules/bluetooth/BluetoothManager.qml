pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool panelVisible: false
    property var panelScreen: null

    // Tooltip state
    property bool tooltipVisible: false
    property var tooltipScreen: null
    property real tooltipX: 0

    property bool powered: false
    property bool scanning: false
    property list<var> devices: []
    property string connectingTo: ""
    property string connectError: ""
    property string pairingPin: ""

    readonly property list<var> connectedDevices: devices.filter(d => d.connected)
    readonly property bool hasConnected: connectedDevices.length > 0

    function togglePanel() {
        panelVisible = !panelVisible
        if (panelVisible) {
            initialLoaded = false
            refreshDevices()
        }
    }

    property bool initialLoaded: false

    function togglePower() {
        powerToggleProc.command = ["bluetoothctl", "power", powered ? "off" : "on"]
        powerToggleProc.running = true
    }

    function scan() {
        scanning = true
        scanProc.running = true
    }

    function connectDevice(mac) {
        connectingTo = mac
        connectError = ""
        pairingPin = ""
        connectProc.command = ["bluetoothctl", "connect", mac]
        connectProc.running = true
    }

    function disconnectDevice(mac) {
        disconnectProc.command = ["bluetoothctl", "disconnect", mac]
        disconnectProc.running = true
    }

    function removeDevice(mac) {
        removeProc.command = ["bluetoothctl", "remove", mac]
        removeProc.running = true
    }

    function refreshDevices() {
        deviceBuffer = []
        devicesProc.running = true
    }

    property list<var> deviceBuffer: []
    property list<string> infoQueue: []
    property int infoIndex: 0

    // ── Poll power state ──
    Process {
        id: powerProc
        command: ["bluetoothctl", "show"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()
                if (trimmed.startsWith("Powered:")) {
                    root.powered = trimmed.indexOf("yes") >= 0
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: powerProc.running = true
    }

    // Auto-refresh while panel is open
    Timer {
        interval: 5000
        running: root.panelVisible && !root.scanning && root.initialLoaded
        repeat: true
        onTriggered: root.refreshDevices()
    }

    // ── Toggle power ──
    Process {
        id: powerToggleProc
        onRunningChanged: {
            if (!running) {
                powerProc.running = true
                if (root.panelVisible) refreshDevices()
            }
        }
    }

    // ── List paired devices ──
    Process {
        id: devicesProc
        command: ["bluetoothctl", "devices"]
        stdout: SplitParser {
            onRead: data => {
                // Format: "Device XX:XX:XX:XX:XX:XX Name"
                var parts = data.split(" ")
                if (parts.length >= 3 && parts[0] === "Device") {
                    var mac = parts[1]
                    var name = parts.slice(2).join(" ")
                    root.deviceBuffer.push({
                        mac: mac,
                        name: name,
                        connected: false,
                        paired: true,
                        icon: "bluetooth",
                        type: "unknown",
                        battery: -1
                    })
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                // Now check info for each device
                root.infoQueue = root.deviceBuffer.map(d => d.mac)
                root.infoIndex = 0
                processNextInfo()
            }
        }
    }

    function processNextInfo() {
        if (infoIndex < infoQueue.length) {
            infoProc.command = ["bluetoothctl", "info", infoQueue[infoIndex]]
            infoProc.running = true
        } else {
            // All done
            root.devices = root.deviceBuffer
            root.initialLoaded = true
        }
    }

    Process {
        id: infoProc
        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()
                var idx = root.infoIndex
                if (idx >= root.deviceBuffer.length) return

                if (trimmed.startsWith("Connected:")) {
                    root.deviceBuffer[idx].connected = trimmed.indexOf("yes") >= 0
                } else if (trimmed.startsWith("Paired:")) {
                    root.deviceBuffer[idx].paired = trimmed.indexOf("yes") >= 0
                } else if (trimmed.startsWith("Battery Percentage:")) {
                    var bMatch = trimmed.match(/\((\d+)\)/)
                    if (bMatch)
                        root.deviceBuffer[idx].battery = parseInt(bMatch[1])
                } else if (trimmed.startsWith("Icon:")) {
                    var iconType = trimmed.split(":")[1].trim()
                    root.deviceBuffer[idx].type = iconType
                    // Map bluetoothctl icon types to material icons
                    if (iconType.indexOf("audio") >= 0)
                        root.deviceBuffer[idx].icon = "headphones"
                    else if (iconType.indexOf("input") >= 0)
                        root.deviceBuffer[idx].icon = "keyboard"
                    else if (iconType.indexOf("phone") >= 0)
                        root.deviceBuffer[idx].icon = "smartphone"
                    else if (iconType.indexOf("computer") >= 0)
                        root.deviceBuffer[idx].icon = "computer"
                    else
                        root.deviceBuffer[idx].icon = "bluetooth"
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                root.infoIndex++
                root.processNextInfo()
            }
        }
    }

    // ── Scan ──
    Process {
        id: scanProc
        command: ["bluetoothctl", "--timeout", "10", "scan", "on"]
        onRunningChanged: {
            if (!running) {
                root.scanning = false
                root.refreshDevices()
            }
        }
    }

    // ── Connect ──
    Process {
        id: connectProc
        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()
                // Capture pairing PIN/passkey from stdout
                // Typical formats:
                //   [agent] Confirm passkey 123456 (yes/no):
                //   [agent] PIN code: 1234
                //   Request confirmation ... Passkey: 123456
                var passMatch = trimmed.match(/[Pp]ass(?:key|code)[:\s]+(\d+)/)
                if (passMatch) {
                    root.pairingPin = passMatch[1]
                    return
                }
                var pinMatch = trimmed.match(/PIN[:\s]+(\d+)/)
                if (pinMatch) {
                    root.pairingPin = pinMatch[1]
                }
            }
        }
        stderr: SplitParser {
            onRead: data => {
                root.connectError = data
            }
        }
        onRunningChanged: {
            if (!running) {
                root.connectingTo = ""
                root.pairingPin = ""
                root.refreshDevices()
            }
        }
    }

    // ── Disconnect ──
    Process {
        id: disconnectProc
        onRunningChanged: {
            if (!running) {
                root.refreshDevices()
            }
        }
    }

    // ── Remove / Unpair ──
    Process {
        id: removeProc
        onRunningChanged: {
            if (!running) {
                root.refreshDevices()
            }
        }
    }
}
