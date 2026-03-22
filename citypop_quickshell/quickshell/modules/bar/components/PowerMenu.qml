import QtQuick
import QtQuick.Layouts
import "../../../Singleton"
import "../../../common"
import "../../powermenu"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    implicitWidth: powerIcon.implicitWidth
    implicitHeight: powerIcon.implicitHeight

    MaterialIcon {
        id: powerIcon
        text: "power_settings_new"
        font.pixelSize: Math.round(18 * root.sf)
        color: PowerMenuState.visible ? Style.accentMagenta : Style.textSecondary
        fill: PowerMenuState.visible ? 1 : 0

        Behavior on color {
            ColorAnimation { duration: Style.animFast }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            PowerMenuState.screen = root.screen
            PowerMenuState.visible = !PowerMenuState.visible
        }
    }
}
