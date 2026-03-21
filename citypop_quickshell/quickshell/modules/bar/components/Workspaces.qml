pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../../Singleton"

RowLayout {
    property real sf: 1.0

    spacing: Math.round(Style.spaceSm * sf)

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: ws
            required property var modelData

            readonly property bool isActive: Hyprland.focusedWorkspace === modelData
            readonly property real sf: parent.sf

            implicitWidth: Math.round((isActive ? 24 : 10) * sf)
            implicitHeight: Math.round(10 * sf)
            radius: Style.radiusFull
            color: isActive ? Style.accentPink : Style.bgTertiary

            Behavior on implicitWidth {
                NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic }
            }

            Behavior on color {
                ColorAnimation { duration: Style.animNormal }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ws.modelData.activate()
            }
        }
    }
}
