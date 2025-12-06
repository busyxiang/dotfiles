import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

import "../../../Singleton"

Item {
    id: root

    // Configurable properties
    property int barHeight: 10
    property int barRadius: 20
    property color backgroundColor: "#50ffffff"
    property color fillColor: "#ff69b4"
    property bool showIcon: false
    property color iconColor: "#ff69b4"
    property int hoverBarHeight: 20  // Height when hovered
    property color hoverBackgroundColor: "#70ffffff"
    property color hoverFillColor: "#ff1493"

    // Expose volume value
    readonly property real volume: Pipewire.defaultAudioSink?.audio.volume ?? 0
    readonly property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false

    // Dynamic icon based on volume and mute state
    readonly property string iconName: {
        if (muted) {
            return "audio-volume-muted-symbolic";
        } else if (volume > 1.0) {
            return "audio-volume-overamplified-symbolic";
        } else if (volume > 0.66) {
            return "audio-volume-high-symbolic";
        } else if (volume > 0.33) {
            return "audio-volume-medium-symbolic";
        } else if (volume > 0.0) {
            return "audio-volume-low-symbolic";
        } else {
            return "audio-volume-muted-symbolic";
        }
    }

    implicitWidth: 100
    implicitHeight: barHeight

    // Bind the pipewire node so its volume will be tracked
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        IconImage {
            visible: root.showIcon
            Layout.preferredHeight: root.barHeight
            Layout.preferredWidth: root.barHeight

            source: root.showIcon ? Quickshell.iconPath(root.iconName) : ""
        }

        Rectangle {
            id: volumeBar
            Layout.fillWidth: true
            Layout.fillHeight: true

            implicitHeight: root.barHeight
            radius: root.barRadius
            color: hoverHandler.hovered ? root.hoverBackgroundColor : root.backgroundColor

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: fillRect
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }

                implicitWidth: parent.width * root.volume
                radius: parent.radius
                color: hoverHandler.hovered ? root.hoverFillColor : root.fillColor

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }

            HoverHandler {
                id: hoverHandler
                cursorShape: Qt.PointingHandCursor

                onHoveredChanged: {
                    if (hovered) {
                        volumeBar.implicitHeight = root.hoverBarHeight;
                    } else {
                        volumeBar.implicitHeight = root.barHeight;
                    }
                }
            }

            MouseArea {
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

                function updateVolume(x) {
                    // Clamp x to be within the bar bounds first
                    var clampedX = Math.max(0.0, Math.min(volumeBar.width, x));
                    var newVolume = (clampedX / volumeBar.width) * 1.0;
                    // Ensure volume stays within 0.0 to 1.0 range
                    newVolume = Math.max(0.0, Math.min(1.0, newVolume));
                    if (Pipewire.defaultAudioSink?.audio) {
                        Pipewire.defaultAudioSink.audio.volume = newVolume;
                    }
                }
            }
        }
    }
}
