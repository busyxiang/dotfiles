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

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Math.round(Style.spaceSm * root.sf)

        MaterialIcon {
            id: clipIcon
            text: "content_paste"
            font.pixelSize: Math.round(16 * root.sf)
            color: ClipboardState.visible ? Style.accentPink : Style.textSecondary
            fill: 0
            Behavior on color { ColorAnimation { duration: Style.animFast } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var wasOpen = ClipboardState.visible
            PanelManager.closeAll()
            if (!wasOpen) {
                ClipboardState.screen = root.screen
                ClipboardState.visible = true
            }
        }
    }
}
