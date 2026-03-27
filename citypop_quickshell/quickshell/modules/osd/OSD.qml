pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../Singleton"
import "../../common"

Scope {
    id: root

    // ── OSD type: "volume" | "toggle" ──
    property string osdType: "volume"
    property bool osdRequested: false

    // ── Volume state ──
    property real lastVolume: -1

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property real currentVolume: Pipewire.defaultAudioSink?.audio.volume ?? 0
    readonly property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false

    function getVolumeColor() {
        if (muted) return Style.textDimmed
        var pct = Math.round(currentVolume * 100)
        if (pct > 130) return Style.colorUrgent
        if (pct > 100) return Style.accentAmber
        return Style.accentPink
    }

    readonly property string volumeIcon: {
        if (muted) return "volume_off"
        if (currentVolume > 0.66) return "volume_up"
        if (currentVolume > 0.0) return "volume_down"
        return "volume_mute"
    }

    onCurrentVolumeChanged: {
        if (lastVolume >= 0 && Math.abs(currentVolume - lastVolume) > 0.001) {
            osdType = "volume"
            showOsd(1500)
        }
        lastVolume = currentVolume
    }

    onMutedChanged: {
        if (lastVolume >= 0) {
            osdType = "volume"
            showOsd(1500)
        }
    }

    // ── Keyboard toggle state ──
    property bool capsLock: false
    property bool numLock: false
    property bool initialLoadDone: false
    property string toggleName: ""
    property bool toggleState: false

    Process {
        id: keyProc
        command: ["sh", "-c",
            "cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -1; " +
            "cat /sys/class/leds/input*::numlock/brightness 2>/dev/null | head -1"
        ]

        property var lines: []

        stdout: SplitParser {
            onRead: data => {
                keyProc.lines.push(data.trim())
            }
        }

        onExited: {
            var newCaps = keyProc.lines.length > 0 && keyProc.lines[0] === "1"
            var newNum = keyProc.lines.length > 1 && keyProc.lines[1] === "1"
            keyProc.lines = []

            if (root.initialLoadDone) {
                if (newCaps !== root.capsLock) {
                    root.capsLock = newCaps
                    root.toggleName = "Caps Lock"
                    root.toggleState = newCaps
                    root.osdType = "toggle"
                    showOsd(1000)
                }
                if (newNum !== root.numLock) {
                    root.numLock = newNum
                    root.toggleName = "Num Lock"
                    root.toggleState = newNum
                    root.osdType = "toggle"
                    showOsd(1000)
                }
            } else {
                root.capsLock = newCaps
                root.numLock = newNum
                root.initialLoadDone = true
            }
        }
    }

    Timer {
        id: keyPollTimer
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            if (!keyProc.running)
                keyProc.running = true
        }
    }

    Component.onCompleted: keyProc.running = true

    // ── Show/hide logic ──
    function showOsd(timeout) {
        osdRequested = true
        hideTimer.interval = timeout
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        onTriggered: root.osdRequested = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            visible: osdContent.opacity > 0
            color: "transparent"
            focusable: false

            implicitWidth: 260
            implicitHeight: 72

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore

            // ── Animated container — bottom center ──
            Item {
                id: osdContent
                width: 260
                height: 72
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 120
                opacity: 0
                scale: 0.92

                states: [
                    State {
                        name: "visible"
                        when: root.osdRequested
                        PropertyChanges { target: osdContent; opacity: 1; scale: 1.0 }
                    },
                    State {
                        name: "hidden"
                        when: !root.osdRequested
                        PropertyChanges { target: osdContent; opacity: 0; scale: 0.95 }
                    }
                ]

                transitions: [
                    Transition {
                        from: "hidden"; to: "visible"
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; duration: 180; easing.type: Easing.OutCubic }
                            NumberAnimation { property: "scale"; duration: 200; easing.type: Easing.OutCubic }
                        }
                    },
                    Transition {
                        from: "visible"; to: "hidden"
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; duration: 250; easing.type: Easing.InCubic }
                            NumberAnimation { property: "scale"; duration: 250; easing.type: Easing.InCubic }
                        }
                    }
                ]

                // ── Overdrive glow ──
                Rectangle {
                    anchors.fill: pill
                    anchors.margins: -8
                    radius: Style.radiusFull + 8
                    color: "transparent"
                    border.width: 0
                    visible: root.osdType === "volume" && root.currentVolume > 1.0 && !root.muted

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        opacity: glowPulse.glowOpacity

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: root.currentVolume > 1.3 ? Style.colorUrgent : Style.accentAmber
                            opacity: 0.15

                            Behavior on color { ColorAnimation { duration: Style.animNormal } }
                        }

                        // Outer glow ring
                        border.width: 2
                        border.color: root.currentVolume > 1.3 ? Style.colorUrgent : Style.accentAmber

                        Behavior on border.color { ColorAnimation { duration: Style.animNormal } }

                        SequentialAnimation {
                            id: glowPulse
                            running: root.osdType === "volume" && root.currentVolume > 1.0 && !root.muted && root.osdRequested
                            loops: Animation.Infinite
                            property real glowOpacity: 0.4

                            NumberAnimation {
                                target: glowPulse; property: "glowOpacity"
                                from: 0.3; to: 0.7; duration: 800
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: glowPulse; property: "glowOpacity"
                                from: 0.7; to: 0.3; duration: 800
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }

                // ── Pill background ──
                Rectangle {
                    id: pill
                    anchors.fill: parent
                    radius: Style.radiusFull
                    color: Qt.rgba(Style.bgSecondary.r, Style.bgSecondary.g, Style.bgSecondary.b, 0.94)
                    border.width: 1
                    border.color: root.osdType === "volume" && root.currentVolume > 1.0 && !root.muted
                        ? (root.currentVolume > 1.3 ? Style.urgentGlow : Style.amberGlow)
                        : Style.bgTertiary

                    Behavior on border.color { ColorAnimation { duration: Style.animNormal } }

                    // ── Volume layout ──
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Style.spaceXl
                        anchors.rightMargin: Style.spaceXl + 4
                        spacing: Style.spaceLg
                        visible: root.osdType === "volume"

                        MaterialIcon {
                            text: root.volumeIcon
                            font.pixelSize: 28
                            color: root.getVolumeColor()
                            fill: 1

                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                        }

                        ColumnLayout {
                            spacing: Style.spaceSm
                            Layout.fillWidth: true

                            StyledText {
                                text: root.muted ? "Muted" : Math.round(root.currentVolume * 100) + "%"
                                font.bold: true
                                font.pixelSize: Style.fontSizeMd
                                color: root.getVolumeColor()

                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                            }

                            VUMeter {
                                Layout.fillWidth: true
                                segments: 16
                                value: root.currentVolume / 1.5
                                muted: root.muted
                                warnAt: 0.7; critAt: 0.867
                                animDuration: 60
                            }
                        }
                    }

                    // ── Toggle layout (Caps Lock / Num Lock) ──
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Style.spaceXl
                        anchors.rightMargin: Style.spaceXl
                        spacing: Style.spaceLg
                        visible: root.osdType === "toggle"

                        MaterialIcon {
                            text: root.toggleName === "Caps Lock" ? "keyboard_capslock" : "dialpad"
                            font.pixelSize: 28
                            color: root.toggleState ? Style.accentPink : Style.textDimmed
                            fill: root.toggleState ? 1 : 0

                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                        }

                        StyledText {
                            text: root.toggleName
                            font.bold: true
                            font.pixelSize: Style.fontSizeMd
                            Layout.fillWidth: true
                        }

                        // ON/OFF badge
                        Rectangle {
                            implicitWidth: badgeText.implicitWidth + Style.spaceXl
                            implicitHeight: 26
                            radius: Style.radiusFull
                            color: root.toggleState ? Style.accentPink : "transparent"
                            border.width: root.toggleState ? 0 : 1
                            border.color: Style.textDimmed

                            Behavior on color { ColorAnimation { duration: Style.animNormal } }
                            Behavior on border.color { ColorAnimation { duration: Style.animNormal } }

                            StyledText {
                                id: badgeText
                                anchors.centerIn: parent
                                text: root.toggleState ? "ON" : "OFF"
                                font.bold: true
                                font.pixelSize: 12
                                color: root.toggleState ? Style.bgPrimary : Style.textDimmed

                                Behavior on color { ColorAnimation { duration: Style.animNormal } }
                            }
                        }
                    }
                }
            }
        }
    }
}
