pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../../Singleton"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    MouseArea {
        anchors.fill: parent
        onWheel: event => {
            if (event.angleDelta.y > 0)
                Hyprland.dispatch("workspace m-1")
            else if (event.angleDelta.y < 0)
                Hyprland.dispatch("workspace m+1")
        }
    }

    RowLayout {
        id: row
        spacing: Math.round(Style.spaceSm * root.sf)

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: ws
            required property var modelData

            readonly property bool isActive: Hyprland.focusedWorkspace === modelData
                && Hyprland.focusedMonitor === root.monitor
            readonly property bool onThisMonitor: modelData.monitor === root.monitor

            visible: onThisMonitor
            implicitWidth: visible ? Math.round((isActive ? 24 : 10) * root.sf) : 0
            implicitHeight: Math.round(10 * root.sf)
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
}
