pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool visible: false
    property var screen: null

    // Package lists: [{ name, oldVer, newVer }]
    property var pacmanUpdates: []
    property var aurUpdates: []
    readonly property int totalCount: pacmanUpdates.length + aurUpdates.length

    property bool checking: false
    property bool checkError: false

    // --- Fetch logic ---
    Timer {
        interval: 2 * 60 * 60 * 1000  // 2 hours
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkUpdates()
    }

    function checkUpdates(): void {
        checking = true
        checkError = false
        _pacmanLines = []
        _aurLines = []
        pacmanProc.running = true
    }

    property var _pacmanLines: []
    property var _aurLines: []

    // Critical packages that may require reboot or break things
    readonly property var _criticalPkgs: [
        "linux", "linux-lts", "linux-zen", "linux-hardened",
        "linux-headers", "linux-lts-headers", "linux-zen-headers",
        "glibc", "systemd", "systemd-libs",
        "mesa", "vulkan-radeon", "vulkan-intel", "nvidia", "nvidia-utils",
        "wayland", "xorg-server",
        "grub", "efibootmgr", "mkinitcpio",
        "dbus", "openssl", "ca-certificates",
        "pacman", "archlinux-keyring"
    ]

    function isCritical(name: string): bool {
        return _criticalPkgs.indexOf(name) >= 0
    }

    function _sortCriticalFirst(pkgs: var): var {
        return pkgs.slice().sort(function(a, b) {
            if (a.critical && !b.critical) return -1
            if (!a.critical && b.critical) return 1
            return 0
        })
    }

    function _parseLine(line: string): var {
        // Format: "name oldver -> newver"
        var parts = line.trim().split(/\s+/)
        if (parts.length >= 4 && parts[2] === "->") {
            var pkgName = parts[0]
            return { name: pkgName, oldVer: parts[1], newVer: parts[3], critical: isCritical(pkgName) }
        }
        return null
    }

    Process {
        id: pacmanProc
        command: ["checkupdates"]
        stdout: SplitParser {
            onRead: data => {
                var pkg = root._parseLine(data)
                if (pkg) root._pacmanLines.push(pkg)
            }
        }
        onExited: (exitCode, exitStatus) => {
            // checkupdates returns 2 when no updates, 0 when updates available
            if (exitCode === 0 || exitCode === 2) {
                root.pacmanUpdates = root._sortCriticalFirst(root._pacmanLines)
                aurProc.running = true
            } else {
                root.checkError = true
                root.checking = false
            }
        }
    }

    Process {
        id: aurProc
        command: ["yay", "-Qua"]
        stdout: SplitParser {
            onRead: data => {
                var pkg = root._parseLine(data)
                if (pkg) root._aurLines.push(pkg)
            }
        }
        onExited: (exitCode, exitStatus) => {
            // yay -Qua returns 1 when no updates
            if (exitCode === 0 || exitCode === 1) {
                root.aurUpdates = root._sortCriticalFirst(root._aurLines)
            } else {
                root.checkError = true
            }
            root.checking = false
        }
    }

    // Open kitty terminal with update command
    Process {
        id: updateProc
        command: ["kitty", "--title", "System Update", "bash", "-c", "yay -Syu; echo ''; echo 'Press any key to close...'; read -n1"]
    }

    function runUpdate(): void {
        updateProc.startDetached()
    }
}
