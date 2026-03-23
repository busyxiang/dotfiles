pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../Singleton"
import "../../../common"

Item {
    id: root
    property real sf: 1.0

    property string imName: "keyboard-us"
    property string displayLabel: "EN"
    property string pendingLabel: "EN"

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    function labelFromIm(name) {
        if (name.indexOf("pinyin") >= 0) return "中"
        if (name.indexOf("mozc") >= 0 || name.indexOf("anthy") >= 0) return "JP"
        if (name.indexOf("hangul") >= 0) return "KO"
        if (name.indexOf("keyboard-") >= 0) {
            var code = name.split("-")[1] || ""
            if (code === "us") return "EN"
            if (code === "jp") return "JP"
            if (code === "kr") return "KO"
            return code.substring(0, 2).toUpperCase()
        }
        return name.substring(0, 2).toUpperCase()
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Math.round(Style.spaceSm * sf)

        MaterialIcon {
            text: "keyboard"
            font.pixelSize: Math.round(16 * root.sf)
            color: Style.accentPink
            fill: 0
        }

        StyledText {
            id: labelText
            text: root.displayLabel
            font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
            color: Style.textSecondary
        }
    }

    // Fade transition when label changes
    SequentialAnimation {
        id: fadeAnim
        NumberAnimation { target: labelText; property: "opacity"; to: 0; duration: 80 }
        ScriptAction { script: root.displayLabel = root.pendingLabel }
        NumberAnimation { target: labelText; property: "opacity"; to: 1; duration: 80 }
    }

    function applyLabel(newLabel) {
        if (newLabel !== displayLabel) {
            pendingLabel = newLabel
            fadeAnim.start()
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleProc.running = true
    }

    // Query current IM via fcitx5
    Process {
        id: queryProc
        command: ["fcitx5-remote", "-n"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()
                if (trimmed !== "") {
                    root.imName = trimmed
                    root.applyLabel(root.labelFromIm(trimmed))
                }
            }
        }
    }

    // Toggle IM
    Process {
        id: toggleProc
        command: ["fcitx5-remote", "-t"]

        onExited: queryDelay.start()
    }

    Timer {
        id: queryDelay
        interval: 200
        onTriggered: {
            if (!queryProc.running)
                queryProc.running = true
        }
    }

    // Poll periodically (catches external toggles via keybinding)
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!queryProc.running)
                queryProc.running = true
        }
    }
}
