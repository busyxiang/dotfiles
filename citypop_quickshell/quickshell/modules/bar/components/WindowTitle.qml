pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../../Singleton"
import "../../../common"

Rectangle {
    id: root
    property real sf: 1.0

    property string appClass: ""
    property string iconSource: ""
    property string displayClass: ""

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

    visible: appClass !== ""
    implicitWidth: visible ? contentRow.implicitWidth + Style.spaceMd * 2 : 0
    implicitHeight: Math.round(22 * sf)
    radius: Style.radiusFull
    color: Style.bgTertiary

    Behavior on implicitWidth {
        NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic }
    }

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
                    var cls = obj.initialClass || obj.class || ""
                    root.updateFromClass(cls)
                    // Trigger fade transition
                    if (cls !== root.displayClass) {
                        fadeOut.start()
                    }
                } catch(e) {}
            }
        }
    }

    // Fade transition
    SequentialAnimation {
        id: fadeOut
        NumberAnimation {
            target: contentRow; property: "opacity"
            to: 0; duration: 100; easing.type: Easing.InCubic
        }
        ScriptAction {
            script: root.displayClass = root.appClass
        }
        NumberAnimation {
            target: contentRow; property: "opacity"
            to: 1; duration: 150; easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: displayClass = appClass

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Math.round(Style.spaceSm * root.sf)

        Image {
            source: root.iconSource
            visible: status === Image.Ready
            sourceSize.width: Math.round(14 * root.sf)
            sourceSize.height: Math.round(14 * root.sf)
            Layout.preferredWidth: Math.round(14 * root.sf)
            Layout.preferredHeight: Math.round(14 * root.sf)
        }

        StyledText {
            text: root.displayClass
            color: Style.textSecondary
            font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
            elide: Text.ElideRight
        }
    }
}
