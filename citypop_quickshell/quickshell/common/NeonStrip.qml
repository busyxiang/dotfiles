import QtQuick
import "../Singleton"

// 2px neon accent strip — anchored to top of parent.
Rectangle {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 2
    radius: parent.radius ?? Style.radiusLg
    color: Style.accentPink
    opacity: 0.8
    z: 1
}
