pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../Singleton"
import "../../../common"
import "../../clipboard"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    // Pink hover circle
    Rectangle {
        anchors.centerIn: parent
        width: Math.round(24 * root.sf)
        height: Math.round(24 * root.sf)
        radius: width / 2
        color: Style.accentPink
        opacity: clipHover.containsMouse ? 0.15 : 0
        scale: clipHover.containsMouse ? 1.0 : 0.8

        Behavior on opacity { NumberAnimation { duration: Style.animFast } }
        Behavior on scale { NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic } }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Math.round(Style.spaceSm * root.sf)

        MaterialIcon {
            id: clipIcon
            text: "content_paste"
            font.pixelSize: Math.round(16 * root.sf)
            color: ClipboardState.visible ? Style.accentPink
                 : clipHover.containsMouse ? Style.textPrimary
                 : Style.textSecondary
            fill: 0
            Behavior on color { ColorAnimation { duration: Style.animFast } }
        }
    }

    MouseArea {
        id: clipHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            ClipboardState.panelX = root.mapToItem(null, root.width / 2, 0).x
            var wasOpen = ClipboardState.visible
            PanelManager.closeAll()
            if (!wasOpen) {
                ClipboardState.screen = root.screen
                ClipboardState.visible = true
            }
        }
    }
}
