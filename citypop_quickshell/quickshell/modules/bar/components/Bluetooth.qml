import QtQuick
import QtQuick.Layouts
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

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            BluetoothManager.panelScreen = root.screen
            BluetoothManager.togglePanel()
        }
    }
}
