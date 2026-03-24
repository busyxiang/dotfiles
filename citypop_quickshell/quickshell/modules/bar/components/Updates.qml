pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../Singleton"
import "../../../common"
import "../../updates"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    readonly property bool hasUpdates: UpdateState.totalCount > 0
    readonly property bool hasCritical: {
        for (var i = 0; i < UpdateState.pacmanUpdates.length; i++)
            if (UpdateState.pacmanUpdates[i].critical) return true
        for (var j = 0; j < UpdateState.aurUpdates.length; j++)
            if (UpdateState.aurUpdates[j].critical) return true
        return false
    }

    implicitWidth: archIcon.implicitWidth
    implicitHeight: archIcon.implicitHeight

    // Loading pulse when checking
    SequentialAnimation {
        running: UpdateState.checking
        loops: Animation.Infinite
        NumberAnimation { target: archIcon; property: "opacity"; from: 1.0; to: 0.3; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { target: archIcon; property: "opacity"; from: 0.3; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        onRunningChanged: { if (!running) archIcon.opacity = 1.0 }
    }

    StyledText {
        id: archIcon
        anchors.centerIn: parent
        text: "\uf303"
        font.pixelSize: Math.round(18 * root.sf)
        color: Style.accentPink
    }

    // Superscript badge (top-right, overlapping)
    Rectangle {
        visible: root.hasUpdates
        x: archIcon.x + archIcon.width - width / 2
        y: archIcon.y - height / 3
        implicitWidth: Math.max(Math.round(14 * root.sf), badgeText.implicitWidth + Math.round(6 * root.sf))
        implicitHeight: Math.round(14 * root.sf)
        radius: Style.radiusFull
        color: root.hasCritical ? Style.accentAmber : Style.accentPink

        StyledText {
            id: badgeText
            anchors.centerIn: parent
            text: UpdateState.totalCount
            font.pixelSize: Math.round(8 * root.sf)
            font.bold: true
            color: Style.bgPrimary
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var wasOpen = UpdateState.visible
            PanelManager.closeAll()
            if (!wasOpen) {
                UpdateState.screen = root.screen
                UpdateState.visible = true
            }
        }
    }
}
