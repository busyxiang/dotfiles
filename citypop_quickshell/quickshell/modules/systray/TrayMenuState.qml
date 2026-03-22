pragma Singleton

import Quickshell

Singleton {
    property bool visible: false
    property var screen: null
    property var menuHandle: null
    property real anchorX: 0
    property real anchorY: 0

    function show(screen_, menuHandle_, x, y) {
        screen = screen_
        menuHandle = menuHandle_
        anchorX = x
        anchorY = y
        visible = true
    }

    function close() {
        visible = false
        menuHandle = null
    }
}
