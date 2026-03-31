pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    property bool locked: false
    property var screen: null

    function _ensureScreen(): void {
        if (screen) return
        var screens = Quickshell.screens
        for (var i = 0; i < screens.length; i++) {
            if (screens[i].name === "DP-2") { screen = screens[i]; return }
        }
        screen = screens[0]
    }

    function lock(): void {
        _ensureScreen()
        locked = true
    }

    // Focus primary monitor then lock, so password input gets keyboard focus
    Process {
        id: focusProc
        command: ["hyprctl", "dispatch", "focusmonitor", LockState.screen?.name ?? ""]
        onExited: LockState.locked = true
    }

    // IPC target: `qs ipc call lock lock`
    IpcHandler {
        target: "lock"
        function lock(): void {
            LockState._ensureScreen()
            focusProc.running = true
        }
    }
}
