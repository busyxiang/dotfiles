import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../Singleton"
import "../../common"

Scope {
    id: root

    property real lastVolume: -1
    property bool osdVisible: false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property real currentVolume: Pipewire.defaultAudioSink?.audio.volume ?? 0
    readonly property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false

    readonly property string iconName: {
        if (muted) return "volume_off"
        if (currentVolume > 0.66) return "volume_up"
        if (currentVolume > 0.33) return "volume_down"
        if (currentVolume > 0.0) return "volume_down"
        return "volume_off"
    }

    onCurrentVolumeChanged: {
        if (lastVolume >= 0 && Math.abs(currentVolume - lastVolume) > 0.001) {
            osdVisible = true
            hideTimer.restart()
        }
        lastVolume = currentVolume
    }

    onMutedChanged: {
        osdVisible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.osdVisible = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.osdVisible
            color: "transparent"
            focusable: false

            // Only the size of the pill, centered on screen
            implicitWidth: 240
            implicitHeight: 64

            exclusionMode: ExclusionMode.Ignore

            // OSD pill
            Rectangle {
                anchors.fill: parent
                radius: Style.radiusLg
                color: Qt.rgba(0.17, 0.11, 0.24, 0.92)
                border.width: 1
                border.color: Style.bgTertiary

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.spaceLg
                    spacing: Style.spaceLg

                    MaterialIcon {
                        text: root.iconName
                        font.pixelSize: 28
                        color: root.muted ? Style.textDimmed : Style.accentPink
                        fill: 1
                    }

                    ColumnLayout {
                        spacing: Style.spaceSm
                        Layout.fillWidth: true

                        StyledText {
                            text: root.muted ? "Muted" : Math.round(root.currentVolume * 100) + "%"
                            font.bold: true
                            font.pixelSize: Style.fontSizeMd
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Style.bgTertiary

                            Rectangle {
                                width: Math.min(parent.width * root.currentVolume, parent.width)
                                height: parent.height
                                radius: parent.radius
                                color: root.muted ? Style.textDimmed : Style.accentPink

                                Behavior on width {
                                    NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic }
                                }

                                Behavior on color {
                                    ColorAnimation { duration: Style.animFast }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
