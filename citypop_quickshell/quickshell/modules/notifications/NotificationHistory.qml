pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Singleton"
import "../../common"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: historyPanel
            required property var modelData
            screen: modelData
            readonly property real sf: modelData.height / 1080
            property bool _open: NotificationManager.historyVisible && NotificationManager.historyScreen === modelData
            visible: NotificationManager.historyVisible || historyCard.opacity > 0
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore
            margins.top: Math.round(Style.barHeight * historyPanel.sf)

            // Click outside to close (starts below bar)
            MouseArea {
                anchors.fill: parent
                onClicked: NotificationManager.historyVisible = false
            }

            // Dropdown card (top-right, below bar)
            Rectangle {
                id: historyCard
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Math.round(Style.spaceMd * historyPanel.sf)
                anchors.rightMargin: Math.round(Style.spaceMd * historyPanel.sf)
                width: 380
                height: 500
                color: Style.bgSecondary
                radius: Style.radiusLg
                border.width: 1
                border.color: Style.bgTertiary

                opacity: historyPanel._open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: historyPanel._open ? 0 : -8
                    Behavior on y { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                }

                // Prevent clicks on the card from closing the panel
                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.spaceLg
                    spacing: Style.spaceMd

                    // Header
                    RowLayout {
                        spacing: Style.spaceMd

                        StyledText {
                            text: "Notifications"
                            font.pixelSize: Style.fontSizeLg
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        // DND icon + toggle
                        MaterialIcon {
                            text: NotificationManager.dndEnabled ? "do_not_disturb_on" : "do_not_disturb_off"
                            font.pixelSize: 16
                            color: NotificationManager.dndEnabled ? Style.accentPink : Style.textDimmed
                        }

                        Rectangle {
                            implicitWidth: 40
                            implicitHeight: 22
                            radius: 11
                            color: NotificationManager.dndEnabled ? Style.accentPink : Style.bgTertiary

                            Behavior on color {
                                ColorAnimation { duration: Style.animFast }
                            }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: Style.textPrimary
                                y: 3
                                x: NotificationManager.dndEnabled ? parent.width - width - 3 : 3

                                Behavior on x {
                                    NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationManager.dndEnabled = !NotificationManager.dndEnabled
                            }
                        }

                        // Separator
                        Rectangle {
                            width: 1
                            height: 18
                            color: Style.bgTertiary
                        }

                        CloseButton {
                            onClicked: NotificationManager.historyVisible = false
                        }
                    }

                    // Separator line
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Style.bgTertiary
                    }

                    // Content area
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Empty state
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Style.spaceLg
                            visible: NotificationManager.history.length === 0

                            MaterialIcon {
                                text: "notifications"
                                font.pixelSize: 72
                                color: Style.bgTertiary
                                fill: 1
                                Layout.alignment: Qt.AlignHCenter
                            }

                            StyledText {
                                text: "You're all caught up :)"
                                color: Style.textDimmed
                                font.pixelSize: Style.fontSizeMd
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        // Grouped notification list
                        ListView {
                            id: groupedList
                            anchors.fill: parent
                            clip: true
                            spacing: Style.spaceSm
                            visible: NotificationManager.history.length > 0

                            // Rebuild grouped model whenever history changes
                            property var groupedModel: NotificationManager.getGroupedHistory()

                            Connections {
                                target: NotificationManager
                                function onHistoryChanged() {
                                    groupedList.groupedModel = NotificationManager.getGroupedHistory()
                                }
                            }

                            model: groupedList.groupedModel

                            delegate: ColumnLayout {
                                id: groupDelegate
                                required property var modelData
                                required property int index

                                property bool collapsed: false

                                width: groupedList.width
                                spacing: Style.spaceSm

                                // App group header
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: groupHeader.implicitHeight + Style.spaceMd * 2
                                    color: groupHeaderArea.containsMouse ? Style.bgTertiary : Style.bgPrimary
                                    radius: Style.radiusMd

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }

                                    MouseArea {
                                        id: groupHeaderArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: groupDelegate.collapsed = !groupDelegate.collapsed
                                    }

                                    RowLayout {
                                        id: groupHeader
                                        anchors.fill: parent
                                        anchors.margins: Style.spaceMd
                                        spacing: Style.spaceMd

                                        MaterialIcon {
                                            text: groupDelegate.collapsed ? "expand_more" : "expand_less"
                                            font.pixelSize: 16
                                            color: groupHeaderArea.containsMouse ? Style.textSecondary : Style.textDimmed
                                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                                        }

                                        StyledText {
                                            text: groupDelegate.modelData.appName
                                            color: Style.accentAmber
                                            font.pixelSize: Style.fontSizeSm
                                            font.bold: true
                                        }

                                        // Count badge
                                        Rectangle {
                                            implicitWidth: countLabel.implicitWidth + Style.spaceMd * 2
                                            implicitHeight: countLabel.implicitHeight + Style.spaceSm
                                            radius: Style.radiusFull
                                            color: Style.bgTertiary

                                            StyledText {
                                                id: countLabel
                                                anchors.centerIn: parent
                                                text: groupDelegate.modelData.notifications.length.toString()
                                                color: Style.textSecondary
                                                font.pixelSize: Style.fontSizeSm
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Dismiss group button
                                        Rectangle {
                                            implicitWidth: 22
                                            implicitHeight: 22
                                            radius: Style.radiusFull
                                            color: dismissGroupArea.containsMouse ? Style.urgentHover : "transparent"

                                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                text: "close"
                                                font.pixelSize: 14
                                                color: dismissGroupArea.containsMouse ? Style.colorUrgent : Style.textDimmed

                                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                                            }

                                            MouseArea {
                                                id: dismissGroupArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: NotificationManager.dismissGroup(groupDelegate.modelData.appName)
                                            }
                                        }
                                    }
                                }

                                // Nested notification items (collapsible)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Style.spaceMd
                                    spacing: Style.spaceSm
                                    visible: !groupDelegate.collapsed

                                    Repeater {
                                        model: groupDelegate.modelData.notifications

                                        delegate: Rectangle {
                                            id: histItem
                                            required property var modelData
                                            required property int index

                                            property bool bodyExpanded: false

                                            Layout.fillWidth: true
                                            implicitHeight: histContent.implicitHeight + Style.spaceLg * 2
                                            color: histClickArea.containsMouse ? Style.bgTertiary : Style.bgPrimary
                                            radius: Style.radiusMd
                                            border.width: histItem.modelData.isCritical ? 2 : 1
                                            border.color: histItem.modelData.isCritical ? Style.colorUrgent : Style.bgTertiary

                                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                                            // Find index in flat history for dismissal
                                            function findHistoryIndex() {
                                                var history = NotificationManager.history
                                                for (var i = 0; i < history.length; i++) {
                                                    if (history[i].id === histItem.modelData.id)
                                                        return i
                                                }
                                                return -1
                                            }

                                            // Click to invoke default action and dismiss
                                            MouseArea {
                                                id: histClickArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    NotificationManager.invokeDefault(histItem.modelData)
                                                    var idx = histItem.findHistoryIndex()
                                                    if (idx >= 0)
                                                        NotificationManager.dismissNotification(idx)
                                                }
                                            }

                                            // Close button (top-right corner)
                                            MaterialIcon {
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.topMargin: Style.spaceSm
                                                anchors.rightMargin: Style.spaceSm
                                                text: "close"
                                                font.pixelSize: 14
                                                color: Style.textDimmed
                                                z: 1

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        var idx = histItem.findHistoryIndex()
                                                        if (idx >= 0)
                                                            NotificationManager.dismissNotification(idx)
                                                    }
                                                }
                                            }

                                            RowLayout {
                                                id: histContent
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.top: parent.top
                                                anchors.margins: Style.spaceLg
                                                spacing: Style.spaceLg

                                                Image {
                                                    source: histItem.modelData.image || histItem.modelData.appIcon || ""
                                                    visible: status === Image.Ready
                                                    Layout.preferredWidth: 40
                                                    Layout.preferredHeight: 40
                                                    Layout.alignment: Qt.AlignTop
                                                    fillMode: Image.PreserveAspectCrop
                                                    sourceSize.width: 40
                                                    sourceSize.height: 40
                                                }

                                                ColumnLayout {
                                                    spacing: Style.spaceSm
                                                    Layout.fillWidth: true

                                                    // Inline badges (critical/persistent)
                                                    RowLayout {
                                                        spacing: Style.spaceSm
                                                        visible: histItem.modelData.isCritical || histItem.modelData.persistent

                                                        MaterialIcon {
                                                            text: "priority_high"
                                                            font.pixelSize: 14
                                                            color: Style.colorUrgent
                                                            visible: histItem.modelData.isCritical
                                                        }

                                                        MaterialIcon {
                                                            text: "push_pin"
                                                            font.pixelSize: 12
                                                            color: Style.textDimmed
                                                            visible: histItem.modelData.persistent
                                                        }
                                                    }

                                                    StyledText {
                                                        text: histItem.modelData.summary || ""
                                                        font.bold: true
                                                        Layout.fillWidth: true
                                                        Layout.rightMargin: Style.spaceLg
                                                        wrapMode: Text.WordWrap
                                                    }

                                                    // Body text with click-to-expand
                                                    StyledText {
                                                        id: histBodyText
                                                        text: histItem.modelData.body || ""
                                                        color: Style.textSecondary
                                                        font.pixelSize: Style.fontSizeSm
                                                        Layout.fillWidth: true
                                                        wrapMode: Text.WordWrap
                                                        visible: text !== ""
                                                        maximumLineCount: histItem.bodyExpanded ? 999 : 3
                                                        elide: histItem.bodyExpanded ? Text.ElideNone : Text.ElideRight

                                                        property bool wasTruncated: false
                                                        onTruncatedChanged: { if (truncated) wasTruncated = true }
                                                    }

                                                    // "Show more / Show less" toggle
                                                    StyledText {
                                                        text: histItem.bodyExpanded ? "Show less" : "Show more"
                                                        color: Style.accentPink
                                                        font.pixelSize: Style.fontSizeSm
                                                        visible: histBodyText.visible && (histBodyText.truncated || histBodyText.wasTruncated)

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: histItem.bodyExpanded = !histItem.bodyExpanded
                                                        }
                                                    }

                                                    // Action buttons row
                                                    Flow {
                                                        Layout.fillWidth: true
                                                        Layout.topMargin: Style.spaceSm
                                                        spacing: Style.spaceSm
                                                        visible: histItem.modelData.actions.length > 0

                                                        Repeater {
                                                            model: histItem.modelData.actions

                                                            delegate: Rectangle {
                                                                required property var modelData
                                                                required property int index

                                                                implicitWidth: histActionLabel.implicitWidth + Style.spaceLg * 2
                                                                implicitHeight: histActionLabel.implicitHeight + Style.spaceSm * 2
                                                                radius: Style.radiusFull
                                                                color: histActionBtnArea.containsMouse ? Style.accentPink : "transparent"
                                                                border.width: 1
                                                                border.color: Style.accentPink

                                                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                                                StyledText {
                                                                    id: histActionLabel
                                                                    anchors.centerIn: parent
                                                                    text: modelData.text || ""
                                                                    color: histActionBtnArea.containsMouse ? Style.bgPrimary : Style.accentPink
                                                                    font.pixelSize: Style.fontSizeSm

                                                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                                                }

                                                                MouseArea {
                                                                    id: histActionBtnArea
                                                                    anchors.fill: parent
                                                                    hoverEnabled: true
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: {
                                                                        var idx = histItem.findHistoryIndex()
                                                                        NotificationManager.invokeAction(histItem.modelData, index)
                                                                        if (idx >= 0)
                                                                            NotificationManager.dismissNotification(idx)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Clear all button (only when there are notifications)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: Style.radiusSm
                        color: clearAllArea.containsMouse ? Style.bgTertiary : Style.bgPrimary
                        visible: NotificationManager.history.length > 0

                        Behavior on color {
                            ColorAnimation { duration: Style.animFast }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Style.spaceSm

                            MaterialIcon {
                                text: "delete_sweep"
                                font.pixelSize: 16
                                color: Style.accentPink
                            }

                            StyledText {
                                text: "Clear all"
                                font.pixelSize: Style.fontSizeSm
                                color: Style.textSecondary
                            }
                        }

                        MouseArea {
                            id: clearAllArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationManager.clearHistory()
                        }
                    }
                }
            }
        }
    }
}
