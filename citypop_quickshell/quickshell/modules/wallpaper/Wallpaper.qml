pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import "../../Singleton"

Scope {
    id: root

    property string wallpaperPath: ""

    Variants {
        model: Quickshell.screens

        WlrLayershell {
            required property var modelData
            screen: modelData
            color: Style.bgPrimary
            layer: WlrLayer.Background
            namespace: "wallpaper"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore

            // City pop gradient fallback
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "#0d0521" }
                    GradientStop { position: 0.3; color: "#1a0a2e" }
                    GradientStop { position: 0.6; color: "#2b1b3d" }
                    GradientStop { position: 0.85; color: "#1f0f35" }
                    GradientStop { position: 1.0; color: "#0d0521" }
                }
                visible: !wallpaperImage.visible
            }

            // Subtle pink glow at bottom
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * 0.3
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(1.0, 0.41, 0.71, 0.08) }
                }
                visible: !wallpaperImage.visible
            }

            // Wallpaper image
            Image {
                id: wallpaperImage
                anchors.fill: parent
                source: root.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                asynchronous: true
            }
        }
    }
}
