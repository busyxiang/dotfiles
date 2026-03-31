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

    // Pink hover circle
    Rectangle {
        anchors.centerIn: parent
        width: Math.round(24 * root.sf)
        height: Math.round(24 * root.sf)
        radius: width / 2
        color: Style.accentPink
        opacity: updateHover.containsMouse ? 0.15 : 0
        scale: updateHover.containsMouse ? 1.0 : 0.8
        Behavior on opacity { NumberAnimation { duration: Style.animFast } }
        Behavior on scale { NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic } }
    }

    // Loading pulse when checking or retrying
    SequentialAnimation {
        running: UpdateState.checking || UpdateState.retrying
        loops: Animation.Infinite
        NumberAnimation { target: archIcon; property: "opacity"; from: 1.0; to: 0.3; duration: UpdateState.retrying ? 1200 : 600; easing.type: Easing.InOutSine }
        NumberAnimation { target: archIcon; property: "opacity"; from: 0.3; to: 1.0; duration: UpdateState.retrying ? 1200 : 600; easing.type: Easing.InOutSine }
        onRunningChanged: { if (!running) archIcon.opacity = 1.0 }
    }

    StyledText {
        id: archIcon
        anchors.centerIn: parent
        text: "\uf303"
        font.pixelSize: Math.round(18 * root.sf)
        color: updateHover.containsMouse ? Style.textPrimary : Style.accentPink
        Behavior on color { ColorAnimation { duration: Style.animFast } }
    }

    // Superscript badge (top-right, overlapping)
    Rectangle {
        visible: root.hasUpdates && !UpdateState.checkError
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

    // Error badge (top-right, overlapping)
    Rectangle {
        visible: UpdateState.checkError
        x: archIcon.x + archIcon.width - width / 2
        y: archIcon.y - height / 3
        implicitWidth: Math.round(14 * root.sf)
        implicitHeight: Math.round(14 * root.sf)
        radius: Style.radiusFull
        color: Style.accentAmber

        StyledText {
            anchors.centerIn: parent
            text: "!"
            font.pixelSize: Math.round(8 * root.sf)
            font.bold: true
            color: Style.bgPrimary
        }
    }

    MouseArea {
        id: updateHover
        anchors.fill: parent
        hoverEnabled: true
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
