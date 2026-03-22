import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../../Singleton"
import "../../../common"

RowLayout {
    id: root
    property real sf: 1.0

    property string appClass: ""
    property string iconSource: ""

    function updateFromClass(cls) {
        appClass = cls
        if (cls === "") {
            iconSource = ""
            return
        }
        var entry = DesktopEntries.byId(cls) ?? DesktopEntries.heuristicLookup(cls)
        if (entry && entry.icon)
            iconSource = Quickshell.iconPath(entry.icon)
        else
            iconSource = ""
    }

    spacing: Math.round(Style.spaceSm * sf)
    visible: appClass !== ""

    // Re-fetch whenever the active toplevel changes
    readonly property var toplevel: Hyprland.activeToplevel
    onToplevelChanged: proc.running = true

    // Retry icon lookup if class is set but icon didn't resolve
    Timer {
        interval: 250
        running: root.appClass !== "" && root.iconSource === ""
        repeat: true
        onTriggered: root.updateFromClass(root.appClass)
    }

    Process {
        id: proc
        command: ["hyprctl", "activewindow", "-j"]
        running: true
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var obj = JSON.parse(data)
                    root.updateFromClass(obj.initialClass || obj.class || "")
                } catch(e) {}
            }
        }
    }

    Image {
        source: root.iconSource
        visible: status === Image.Ready
        sourceSize.width: Math.round(16 * root.sf)
        sourceSize.height: Math.round(16 * root.sf)
        Layout.preferredWidth: Math.round(16 * root.sf)
        Layout.preferredHeight: Math.round(16 * root.sf)
    }

    StyledText {
        text: root.appClass
        color: Style.textSecondary
        font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
        elide: Text.ElideRight
    }
}
