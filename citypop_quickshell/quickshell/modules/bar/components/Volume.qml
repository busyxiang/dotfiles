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

    implicitWidth: layout.implicitWidth
    implicitHeight: barHeight

    // Bind the pipewire node so its volume will be tracked
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 8

        IconImage {
            visible: root.showIcon
            Layout.preferredHeight: root.barHeight
            Layout.preferredWidth: root.barHeight

            source: root.showIcon ? Quickshell.iconPath(root.iconName) : ""
        }

        Text {
            color: Style.textColor
            font.pixelSize: Style.fontSize
            text: Math.round(root.volume * 100) + "%"
        }

        // Main volume bar container
        Rectangle {
            id: volumeBar
            Layout.preferredWidth: 100

            implicitHeight: root.barHeight
            radius: root.barRadius
            color: hoverHandler.hovered ? root.hoverBackgroundColor : root.backgroundColor

            // Smooth color transition on hover
            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }

            // Smooth height expansion on hover
            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            // Filled portion of the bar representing current volume
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

                // Smooth color transition on hover
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }

            // Handles hover detection and bar expansion
            HoverHandler {
                id: hoverHandler
                cursorShape: Qt.PointingHandCursor
            }

            // Handles click and drag interactions for volume adjustment
            WrapperMouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                property bool isDragging: false

                // Start dragging and set initial volume
                onPressed: mouse => {
                    isDragging = true;
                    updateVolume(mouse.x);
                }

                // Stop dragging
                onReleased: {
                    isDragging = false;
                }

                // Update volume while dragging
                onPositionChanged: mouse => {
                    if (isDragging) {
                        updateVolume(mouse.x);
                    }
                }

                // Handle single click to set volume
                onClicked: mouse => {
                    updateVolume(mouse.x);
                }

                // Handle scroll wheel for volume adjustment
                onWheel: wheel => {
                    if (Pipewire.defaultAudioSink?.audio) {
                        var delta = wheel.angleDelta.y / 120; // Standard scroll step
                        var volumeChange = delta * 0.05; // 5% per scroll step
                        var currentVolume = Pipewire.defaultAudioSink.audio.volume;
                        var newVolume = currentVolume + volumeChange;
                        // Clamp to 0.0 to 1.0 range (0% to 100%)
                        newVolume = Math.max(0.0, Math.min(1.5, newVolume));
                        Pipewire.defaultAudioSink.audio.volume = newVolume;
                    }
                }

                // Convert mouse position to volume value and apply it
                function updateVolume(x) {
                    // Clamp x to be within the bar bounds first
                    var clampedX = Math.max(0.0, Math.min(volumeBar.width, x));
                    var newVolume = (clampedX / volumeBar.width) * 1.0;
                    // Ensure volume stays within 0.0 to 1.0 range (0% to 100%)
                    newVolume = Math.max(0.0, Math.min(1.0, newVolume));
                    if (Pipewire.defaultAudioSink?.audio) {
                        Pipewire.defaultAudioSink.audio.volume = newVolume;
                    }
                }
            }
        }
    }
}
