pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    property bool locked: false
    property var screen: null

    function lock(): void {
        if (!screen) screen = Quickshell.screens[0]
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
            if (!LockState.screen) LockState.screen = Quickshell.screens[0]
            focusProc.running = true
        }
    }
}
