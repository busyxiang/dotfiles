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
            visible: NotificationManager.historyVisible && NotificationManager.historyScreen === modelData
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore

            // Click outside to close (starts below bar)
            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: Style.barHeight
                onClicked: NotificationManager.historyVisible = false
            }

            // Dropdown card (top-right, below bar)
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Style.barHeight + Style.spaceMd
                anchors.rightMargin: Style.spaceMd
                width: 380
                height: 500
                color: Style.bgSecondary
                radius: Style.radiusLg
                border.width: 1
                border.color: Style.bgTertiary

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

                        // Close button
                        Rectangle {
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: Style.radiusSm
                            color: closeArea.containsMouse ? Style.bgTertiary : "transparent"

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "close"
                                font.pixelSize: 16
                                color: Style.textDimmed
                            }

                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationManager.historyVisible = false
                            }
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

                        // Notification list
                        ListView {
                            anchors.fill: parent
                            clip: true
                            spacing: Style.spaceSm
                            model: NotificationManager.history
                            visible: NotificationManager.history.length > 0

                            delegate: Rectangle {
                                id: histItem
                                required property var modelData
                                required property int index

                                width: ListView.view.width
                                implicitHeight: histContent.implicitHeight + Style.spaceLg * 2
                                color: histClickArea.containsMouse ? Style.bgTertiary : Style.bgPrimary
                                radius: Style.radiusMd
                                border.width: 1
                                border.color: Style.bgTertiary

                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                // Click to invoke default action
                                MouseArea {
                                    id: histClickArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: histItem.modelData.actions.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (histItem.modelData.actions.length > 0) {
                                            NotificationManager.invokeAction(histItem.modelData, 0)
                                            NotificationManager.dismissNotification(histItem.index)
                                        }
                                    }
                                }

                                RowLayout {
                                    id: histContent
                                    anchors.fill: parent
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

                                        RowLayout {
                                            spacing: Style.spaceMd

                                            StyledText {
                                                text: histItem.modelData.appName || "Notification"
                                                color: Style.accentAmber
                                                font.pixelSize: Style.fontSizeSm
                                                font.bold: true
                                            }

                                            Item { Layout.fillWidth: true }

                                            MaterialIcon {
                                                text: "close"
                                                font.pixelSize: 14
                                                color: Style.textDimmed

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: NotificationManager.dismissNotification(histItem.index)
                                                }
                                            }
                                        }

                                        StyledText {
                                            text: histItem.modelData.summary || ""
                                            font.bold: true
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                        }

                                        StyledText {
                                            text: histItem.modelData.body || ""
                                            color: Style.textSecondary
                                            font.pixelSize: Style.fontSizeSm
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            visible: text !== ""
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
