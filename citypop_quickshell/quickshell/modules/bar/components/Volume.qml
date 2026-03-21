import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

import "../../../Singleton"
import "../../../common"

Item {
    id: root

    property real sf: 1.0
    property int barHeight: Math.round(10 * sf)
    property int barRadius: 20
    property color backgroundColor: Style.bgTertiary
    property color fillColor: Style.accentPink
    property bool showIcon: false
    property color iconColor: Style.accentPink
    property color hoverBackgroundColor: Qt.lighter(Style.bgTertiary, 1.3)
    property color hoverFillColor: Style.accentMagenta

    readonly property real volume: Pipewire.defaultAudioSink?.audio.volume ?? 0
    readonly property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false

    readonly property string iconName: {
        if (muted) return "volume_off"
        if (volume > 0.66) return "volume_up"
        if (volume > 0.33) return "volume_down"
        if (volume > 0.0) return "volume_down"
        return "volume_off"
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Math.round(Style.spaceMd * root.sf)

        Item {
            implicitWidth: muteIcon.implicitWidth + Math.round(Style.spaceMd * root.sf * 2)
            implicitHeight: muteIcon.implicitHeight + Math.round(Style.spaceMd * root.sf * 2)

            MaterialIcon {
                id: muteIcon
                anchors.centerIn: parent
                text: root.iconName
                font.pixelSize: Math.round(20 * root.sf)
                color: root.muted ? Style.textDimmed : Style.accentPink
                fill: 0

                Behavior on color {
                    ColorAnimation { duration: Style.animFast }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (Pipewire.defaultAudioSink?.audio)
                        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                }
            }
        }

        StyledText {
            text: Math.round(root.volume * 100) + "%"
            font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
            color: Style.textSecondary
        }

        Rectangle {
            id: volumeBar
            Layout.preferredWidth: Math.round(100 * root.sf)
            implicitHeight: root.barHeight
            radius: root.barRadius
            color: hoverHandler.hovered ? root.hoverBackgroundColor : root.backgroundColor

            Behavior on color {
                ColorAnimation { duration: Style.animNormal }
            }

            Behavior on implicitHeight {
                NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic }
            }

            Rectangle {
                id: fillRect
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                implicitWidth: Math.min(parent.width * root.volume, parent.width)
                radius: parent.radius
                color: hoverHandler.hovered ? root.hoverFillColor : root.fillColor

                Behavior on color {
                    ColorAnimation { duration: Style.animNormal }
                }
            }

            HoverHandler {
                id: hoverHandler
                cursorShape: Qt.PointingHandCursor
            }

            WrapperMouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                property bool isDragging: false

                onPressed: mouse => {
                    isDragging = true;
                    updateVolume(mouse.x);
                }

                onReleased: {
                    isDragging = false;
                }

                onPositionChanged: mouse => {
                    if (isDragging) {
                        updateVolume(mouse.x);
                    }
                }

                onClicked: mouse => {
                    updateVolume(mouse.x);
                }

                onWheel: wheel => {
                    if (Pipewire.defaultAudioSink?.audio) {
                        var delta = wheel.angleDelta.y / 120;
                        var volumeChange = delta * 0.05;
                        var currentVolume = Pipewire.defaultAudioSink.audio.volume;
                        var newVolume = Math.max(0.0, Math.min(1.5, currentVolume + volumeChange));
                        Pipewire.defaultAudioSink.audio.volume = newVolume;
                    }
                }

                function updateVolume(x) {
                    var clampedX = Math.max(0.0, Math.min(volumeBar.width, x));
                    var newVolume = Math.max(0.0, Math.min(1.0, clampedX / volumeBar.width));
                    if (Pipewire.defaultAudioSink?.audio) {
                        Pipewire.defaultAudioSink.audio.volume = newVolume;
                    }
                }
            }
        }
    }
}
