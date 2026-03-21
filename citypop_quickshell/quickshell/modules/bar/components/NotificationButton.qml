import QtQuick
import QtQuick.Layouts
import "../../../Singleton"
import "../../../common"
import "../../notifications"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    implicitWidth: bellIcon.implicitWidth
    implicitHeight: bellIcon.implicitHeight

    readonly property bool hasUnread: NotificationManager.unreadCount > 0
    readonly property bool panelOpen: NotificationManager.historyVisible

    MaterialIcon {
        id: bellIcon
        text: root.panelOpen ? "notifications_active" : "notifications"
        font.pixelSize: Math.round(18 * root.sf)
        color: root.panelOpen ? Style.accentMagenta
             : root.hasUnread ? Style.accentPink
             : Style.textSecondary
        fill: root.panelOpen ? 1 : 0

        Behavior on color {
            ColorAnimation { duration: Style.animFast }
        }
    }

    // Unread badge dot
    Rectangle {
        visible: root.hasUnread && !root.panelOpen
        width: Math.round(6 * root.sf)
        height: Math.round(6 * root.sf)
        radius: width / 2
        color: Style.colorUrgent
        anchors.top: bellIcon.top
        anchors.right: bellIcon.right
        anchors.topMargin: -1
        anchors.rightMargin: -1
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            NotificationManager.historyScreen = root.screen
            NotificationManager.toggleHistory()
            if (!NotificationManager.historyVisible)
                NotificationManager.unreadCount = 0
        }
    }
}
