pragma Singleton

import Quickshell

Singleton {
    property bool locked: false
    property var screen: null

    function lock(): void {
        // Default to first screen if no screen specified
        if (!screen) screen = Quickshell.screens[0]
        locked = true
    }
}
