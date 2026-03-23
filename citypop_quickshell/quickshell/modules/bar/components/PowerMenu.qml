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

    // Danger glow on hover
    Rectangle {
        anchors.centerIn: powerIcon
        width: Math.round(24 * root.sf)
        height: Math.round(24 * root.sf)
        radius: width / 2
        color: Style.colorUrgent
        opacity: powerHover.containsMouse ? 0.15 : 0

        Behavior on opacity { NumberAnimation { duration: Style.animFast } }
    }

    MaterialIcon {
        id: powerIcon
        text: "power_settings_new"
        font.pixelSize: Math.round(18 * root.sf)
        color: PowerMenuState.visible ? Style.accentMagenta
             : powerHover.containsMouse ? Style.colorUrgent
             : Style.textSecondary
        fill: PowerMenuState.visible ? 1 : 0

        Behavior on color {
            ColorAnimation { duration: Style.animFast }
        }

        // Rotate on hover
        rotation: powerHover.containsMouse ? 90 : 0
        Behavior on rotation {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: powerHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            PowerMenuState.screen = root.screen
            PowerMenuState.visible = !PowerMenuState.visible
        }
    }
}
