pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../../Singleton"
import "../../../common"
import "../../workspace"

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

            delegate: Item {
                id: ws
                required property var modelData

                readonly property bool isActive: Hyprland.focusedWorkspace === modelData
                    && Hyprland.focusedMonitor === root.monitor
                readonly property bool onThisMonitor: modelData.monitor === root.monitor

                visible: onThisMonitor
                implicitWidth: visible ? Math.round(22 * root.sf) : 0
                implicitHeight: Math.round(22 * root.sf)

                Behavior on implicitWidth {
                    NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic }
                }

                // Neon glow (behind the box, only for active)
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: Style.radiusSm + 3
                    color: "transparent"
                    border.width: 2
                    border.color: Style.accentPink
                    opacity: ws.isActive ? 0.35 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: Style.animNormal }
                    }
                }

                // Number box
                Rectangle {
                    anchors.fill: parent
                    radius: Style.radiusSm
                    color: ws.isActive ? Style.accentPink : "transparent"
                    border.width: ws.isActive ? 0 : 1
                    border.color: Style.accentPurple

                    Behavior on color {
                        ColorAnimation { duration: Style.animNormal }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: Style.animNormal }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: ws.modelData.id ?? ""
                        font.pixelSize: Math.round(11 * root.sf)
                        font.bold: true
                        color: ws.isActive ? Style.bgPrimary : Style.accentPurple

                        Behavior on color {
                            ColorAnimation { duration: Style.animNormal }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ws.modelData.activate()
                    onContainsMouseChanged: {
                        if (containsMouse && !ws.isActive) {
                            var globalPos = ws.mapToItem(null, ws.width / 2, 0)
                            WorkspacePreview.tooltipX = globalPos.x
                            WorkspacePreview.tooltipScreen = root.screen
                            WorkspacePreview.hoveredWsId = ws.modelData.id
                            WorkspacePreview.show()
                        } else {
                            WorkspacePreview.hide()
                        }
                    }
                }
            }
        }
    }
}
