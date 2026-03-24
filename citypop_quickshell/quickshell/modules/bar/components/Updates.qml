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

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // Loading pulse when checking
    SequentialAnimation {
        running: UpdateState.checking
        loops: Animation.Infinite
        NumberAnimation { target: row; property: "opacity"; from: 1.0; to: 0.3; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { target: row; property: "opacity"; from: 0.3; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        onRunningChanged: { if (!running) row.opacity = 1.0 }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Math.round(Style.spaceSm * root.sf)

        StyledText {
            text: "\uf303"
            font.pixelSize: Math.round(18 * root.sf)
            color: Style.accentPink
        }

        // Badge count (only when updates available)
        Rectangle {
            visible: root.hasUpdates
            implicitWidth: Math.max(Math.round(16 * root.sf), badgeText.implicitWidth + Math.round(Style.spaceMd * root.sf))
            implicitHeight: Math.round(16 * root.sf)
            radius: Style.radiusFull
            color: Style.accentPink

            StyledText {
                id: badgeText
                anchors.centerIn: parent
                text: UpdateState.totalCount
                font.pixelSize: Math.round(10 * root.sf)
                font.bold: true
                color: Style.bgPrimary
            }
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
