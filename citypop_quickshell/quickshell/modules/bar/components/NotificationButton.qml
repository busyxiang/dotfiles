pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../Singleton"
import "../../../common"
import "../../notifications"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    implicitWidth: bellIcon.implicitWidth + Math.round(4 * sf)
    implicitHeight: bellIcon.implicitHeight

    readonly property bool hasUnread: NotificationManager.unreadCount > 0
    readonly property bool panelOpen: NotificationManager.historyVisible

    // Track count for wiggle trigger
    property int lastCount: 0

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

        // Wiggle from bell top
        transformOrigin: Item.Top

        SequentialAnimation {
            id: wiggleAnim
            NumberAnimation { target: bellIcon; property: "rotation"; to: 15; duration: 60 }
            NumberAnimation { target: bellIcon; property: "rotation"; to: -12; duration: 60 }
            NumberAnimation { target: bellIcon; property: "rotation"; to: 8; duration: 60 }
            NumberAnimation { target: bellIcon; property: "rotation"; to: -5; duration: 60 }
            NumberAnimation { target: bellIcon; property: "rotation"; to: 0; duration: 60 }
        }
    }

    // Unread count badge
    Rectangle {
        visible: root.hasUnread && !root.panelOpen
        anchors.top: bellIcon.top
        anchors.left: bellIcon.right
        anchors.topMargin: -3
        anchors.leftMargin: -6
        width: Math.max(Math.round(14 * root.sf), countText.implicitWidth + Math.round(6 * root.sf))
        height: Math.round(14 * root.sf)
        radius: height / 2
        color: Style.accentPink

        StyledText {
            id: countText
            anchors.centerIn: parent
            text: NotificationManager.unreadCount > 99 ? "99+" : NotificationManager.unreadCount
            font.pixelSize: Math.round(8 * root.sf)
            font.bold: true
            color: Style.bgPrimary
        }
    }

    // Trigger wiggle on new notifications
    Connections {
        target: NotificationManager
        function onUnreadCountChanged() {
            if (NotificationManager.unreadCount > root.lastCount && NotificationManager.unreadCount > 0) {
                wiggleAnim.start()
            }
            root.lastCount = NotificationManager.unreadCount
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            NotificationManager.panelX = root.mapToItem(null, root.width / 2, 0).x
            var wasOpen = NotificationManager.historyVisible
            PanelManager.closeAll()
            if (!wasOpen) {
                NotificationManager.historyScreen = root.screen
                NotificationManager.historyVisible = true
                NotificationManager.unreadCount = 0
            }
        }
    }
}
