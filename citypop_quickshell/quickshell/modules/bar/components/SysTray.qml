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

    spacing: Math.round(Style.spaceSm * sf)

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem
            required property var modelData

            implicitWidth: Math.round(18 * root.sf)
            implicitHeight: Math.round(18 * root.sf)

            IconImage {
                anchors.fill: parent
                source: trayItem.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
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
