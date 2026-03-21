pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../../Singleton"

RowLayout {
    property real sf: 1.0

    spacing: Math.round(Style.spaceSm * sf)

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem
            required property var modelData

            implicitWidth: Math.round(18 * sf)
            implicitHeight: Math.round(18 * sf)

            IconImage {
                anchors.fill: parent
                source: trayItem.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        trayItem.modelData.activate()
                    else
                        trayItem.modelData.secondaryActivate()
                }
            }
        }
    }
}
