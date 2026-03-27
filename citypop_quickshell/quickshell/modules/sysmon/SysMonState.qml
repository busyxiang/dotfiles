pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool visible: false
    property var screen: null

    property int cpuPercent: 0
    property int cpuTemp: 0
    property string ramUsed: "0.0"
    property string ramTotal: "0.0"
    property int ramPercent: 0
    property int gpuPercent: 0
    property int gpuTemp: 0
    property int fanRpm: 0
    property var topProcesses: []

    // Previous CPU tick values for delta calculation
    property real prevIdle: 0
    property real prevTotal: 0
    property real rawMemTotalKb: 0

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statsProc.running = true
            psProc.running = true
        }
    }

    Process {
        id: statsProc
        command: ["bash", "-c", "head -1 /proc/stat; head -3 /proc/meminfo; cat /sys/class/thermal/thermal_zone0/temp; echo GPU_BUSY:$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo 0); echo GPU_TEMP:$(cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input 2>/dev/null || cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input 2>/dev/null || echo 0); echo FAN_RPM:$(cat /sys/class/hwmon/hwmon*/fan1_input 2>/dev/null || echo 0)"]
        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf("cpu ") === 0) {
                    // Parse CPU: cpu user nice system idle iowait irq softirq steal
                    var parts = data.split(/\s+/)
                    var user = parseFloat(parts[1])
                    var nice = parseFloat(parts[2])
                    var system = parseFloat(parts[3])
                    var idle = parseFloat(parts[4])
                    var iowait = parseFloat(parts[5])
                    var irq = parseFloat(parts[6])
                    var softirq = parseFloat(parts[7])
                    var steal = parseFloat(parts[8]) || 0

                    var totalIdle = idle + iowait
                    var total = user + nice + system + idle + iowait + irq + softirq + steal

                    if (root.prevTotal > 0) {
                        var diffTotal = total - root.prevTotal
                        var diffIdle = totalIdle - root.prevIdle
                        if (diffTotal > 0)
                            root.cpuPercent = Math.round((1 - diffIdle / diffTotal) * 100)
                    }

                    root.prevIdle = totalIdle
                    root.prevTotal = total
                } else if (data.indexOf("MemTotal:") === 0) {
                    var kbTotal = parseInt(data.split(/\s+/)[1])
                    root.rawMemTotalKb = kbTotal
                    root.ramTotal = (kbTotal / 1048576).toFixed(1)
                } else if (data.indexOf("MemAvailable:") === 0) {
                    var kbAvail = parseInt(data.split(/\s+/)[1])
                    var kbUsed = root.rawMemTotalKb - kbAvail
                    root.ramUsed = (kbUsed / 1048576).toFixed(1)
                    if (root.rawMemTotalKb > 0)
                        root.ramPercent = Math.round((kbUsed / root.rawMemTotalKb) * 100)
                } else if (data.indexOf("GPU_BUSY:") === 0) {
                    var gpuVal = parseInt(data.substring(9))
                    if (!isNaN(gpuVal))
                        root.gpuPercent = gpuVal
                } else if (data.indexOf("GPU_TEMP:") === 0) {
                    var gpuTempVal = parseInt(data.substring(9))
                    if (!isNaN(gpuTempVal) && gpuTempVal > 0)
                        root.gpuTemp = Math.round(gpuTempVal / 1000)
                } else if (data.indexOf("FAN_RPM:") === 0) {
                    var fanVal = parseInt(data.substring(8))
                    if (!isNaN(fanVal))
                        root.fanRpm = fanVal
                } else {
                    // CPU temp line — raw integer in millidegrees
                    var temp = parseInt(data)
                    if (!isNaN(temp) && temp > 0)
                        root.cpuTemp = Math.round(temp / 1000)
                }
            }
        }

    }

    Process {
        id: killProc
    }

    function killProcess(pid: int): void {
        killProc.command = ["kill", "-15", String(pid)]
        killProc.running = true
    }

    Process {
        id: psProc
        property var _lines: []
        command: ["bash", "-c", "ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -6"]
        stdout: SplitParser {
            onRead: data => {
                // Skip the header line
                if (data.indexOf("PID") !== -1 || data.indexOf("%CPU") !== -1)
                    return
                var parts = data.trim().split(/\s+/)
                if (parts.length >= 4) {
                    psProc._lines.push({
                        pid: parseInt(parts[0]),
                        name: parts.slice(1, parts.length - 2).join(" "),
                        cpu: parts[parts.length - 2],
                        mem: parts[parts.length - 1]
                    })
                }
            }
        }
        onExited: {
            root.topProcesses = psProc._lines
            psProc._lines = []
        }
    }
}
