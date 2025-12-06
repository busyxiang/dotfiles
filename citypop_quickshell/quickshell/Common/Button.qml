import QtQuick
import Quickshell.Io

QtObject {
    id: button
    required property string text
    required property string icon
    property string command: ""
    property var keybind: null
    property bool quitOnExec: false

    signal clicked

    readonly property var process: Process {
        command: ["sh", "-c", button.command]
    }

    function exec() {
        if (command !== "") {
            process.startDetached();
        }
        clicked();
        if (quitOnExec) {
            Qt.quit();
        }
    }
}
