pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../bluetooth"
import "../../../Singleton"
import "../../../common"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    MaterialIcon {
        id: icon
        text: BluetoothManager.powered ? "bluetooth" : "bluetooth_disabled"
        font.pixelSize: Math.round(18 * root.sf)
        color: BluetoothManager.panelVisible ? Style.accentMagenta
             : BluetoothManager.hasConnected ? Style.accentPink
             : BluetoothManager.powered ? Style.textSecondary
             : Style.textDimmed
        fill: 0

        Behavior on color {
            ColorAnimation { duration: Style.animNormal }
        }
    }

    // Connection count badge
    Rectangle {
        visible: BluetoothManager.connectedDevices.length > 0 && !BluetoothManager.panelVisible
        anchors.top: icon.top
        anchors.right: icon.right
        anchors.topMargin: -2
        anchors.rightMargin: -4
        width: Math.round(12 * root.sf)
        height: Math.round(12 * root.sf)
        radius: width / 2
        color: Style.accentPink

        StyledText {
            anchors.centerIn: parent
            text: BluetoothManager.connectedDevices.length
            font.pixelSize: Math.round(8 * root.sf)
            font.bold: true
            color: Style.bgPrimary
        }
    }

    MouseArea {
        id: btHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            BluetoothManager.panelScreen = root.screen
            BluetoothManager.togglePanel()
        }
        onContainsMouseChanged: {
            if (containsMouse && BluetoothManager.hasConnected) {
                BluetoothManager.tooltipVisible = true
                BluetoothManager.tooltipScreen = root.screen
                var globalPos = root.mapToItem(null, root.width / 2, 0)
                BluetoothManager.tooltipX = globalPos.x
            } else {
                BluetoothManager.tooltipVisible = false
            }
        }
    }
}
