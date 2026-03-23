pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../../Singleton"
import "../../systray"

RowLayout {
    id: root
    property real sf: 1.0
    property var panelWindow: null
    property var screen: null

    readonly property int iconSize: Math.round(18 * sf)
    readonly property int hoverSize: Math.round(24 * sf)

    spacing: Math.round(Style.spaceSm * sf)

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem
            required property var modelData

            implicitWidth: root.hoverSize
            implicitHeight: root.hoverSize

            // Pink hover circle
            Rectangle {
                anchors.centerIn: parent
                width: root.hoverSize
                height: root.hoverSize
                radius: width / 2
                color: Style.accentPink
                opacity: trayHover.containsMouse ? 0.15 : 0
                scale: trayHover.containsMouse ? 1.0 : 0.8

                Behavior on opacity { NumberAnimation { duration: Style.animFast } }
                Behavior on scale { NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic } }
            }

            IconImage {
                anchors.centerIn: parent
                width: root.iconSize
                height: root.iconSize
                source: trayItem.modelData.icon
            }

            MouseArea {
                id: trayHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    var globalX = trayItem.mapToItem(null, mouse.x, mouse.y).x
                    if (mouse.button === Qt.LeftButton) {
                        if (trayItem.modelData.onlyMenu && trayItem.modelData.hasMenu)
                            TrayMenuState.show(root.screen, trayItem.modelData.menu, globalX, 0)
                        else
                            trayItem.modelData.activate()
                    } else if (mouse.button === Qt.RightButton) {
                        if (trayItem.modelData.hasMenu)
                            TrayMenuState.show(root.screen, trayItem.modelData.menu, globalX, 0)
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate()
                    }
                }
            }
        }
    }
}
