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
            required property var modelData
            screen: modelData
            color: "transparent"
            visible: NotificationManager.popups.length > 0

            anchors {
                top: true
                right: true
            }

            implicitWidth: 380
            implicitHeight: popupColumn.implicitHeight + Style.barHeight + Style.spaceLg * 2

            exclusionMode: ExclusionMode.Ignore

            ColumnLayout {
                id: popupColumn
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.topMargin: Style.barHeight + Style.spaceMd
                anchors.margins: Style.spaceMd
                spacing: Style.spaceSm

                Repeater {
                    model: NotificationManager.popups

                    delegate: Rectangle {
                        id: notifCard
                        required property var modelData
                        required property int index

                        property bool bodyExpanded: false

                        Layout.fillWidth: true
                        implicitHeight: notifContent.implicitHeight + Style.spaceLg * 2
                        color: Style.bgSecondary
                        radius: Style.radiusMd
                        border.width: notifCard.modelData.isCritical ? 2 : 1
                        border.color: notifCard.modelData.isCritical ? Style.colorUrgent : Style.bgTertiary

                        // Click card to invoke default action
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: notifCard.modelData.actions.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (notifCard.modelData.actions.length > 0) {
                                    NotificationManager.invokeAction(notifCard.modelData, 0)
                                    NotificationManager.dismissPopupById(notifCard.modelData.id)
                                }
                            }
                        }

                        RowLayout {
                            id: notifContent
                            anchors.fill: parent
                            anchors.margins: Style.spaceLg
                            spacing: Style.spaceLg

                            // Notification image/icon
                            Image {
                                source: notifCard.modelData.image || notifCard.modelData.appIcon || ""
                                visible: status === Image.Ready
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                Layout.alignment: Qt.AlignTop
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 48
                                sourceSize.height: 48
                            }

                            ColumnLayout {
                                spacing: Style.spaceSm
                                Layout.fillWidth: true

                                RowLayout {
                                    spacing: Style.spaceMd

                                    // Critical urgency icon
                                    MaterialIcon {
                                        text: "priority_high"
                                        font.pixelSize: 16
                                        color: Style.colorUrgent
                                        visible: notifCard.modelData.isCritical
                                    }

                                    StyledText {
                                        text: notifCard.modelData.appName || "Notification"
                                        color: notifCard.modelData.isCritical ? Style.colorUrgent : Style.accentPink
                                        font.pixelSize: Style.fontSizeMd
                                        font.bold: true
                                    }

                                    // Persistent pin icon
                                    MaterialIcon {
                                        text: "push_pin"
                                        font.pixelSize: 14
                                        color: Style.textDimmed
                                        visible: notifCard.modelData.persistent
                                    }

                                    Item { Layout.fillWidth: true }

                                    MaterialIcon {
                                        text: "close"
                                        font.pixelSize: 16
                                        color: Style.textDimmed

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationManager.removeById(notifCard.modelData.id)
                                        }
                                    }
                                }

                                StyledText {
                                    text: notifCard.modelData.summary || ""
                                    font.bold: true
                                    font.pixelSize: Style.fontSizeLg
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                // Body text with click-to-expand
                                StyledText {
                                    id: popupBodyText
                                    text: notifCard.modelData.body || ""
                                    color: Style.textSecondary
                                    font.pixelSize: Style.fontSizeMd
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    visible: text !== ""
                                    maximumLineCount: notifCard.bodyExpanded ? 999 : 3
                                    elide: notifCard.bodyExpanded ? Text.ElideNone : Text.ElideRight

                                    property bool wasTruncated: false
                                    onTruncatedChanged: { if (truncated) wasTruncated = true }
                                }

                                // "Show more / Show less" toggle
                                StyledText {
                                    text: notifCard.bodyExpanded ? "Show less" : "Show more"
                                    color: Style.accentPink
                                    font.pixelSize: Style.fontSizeSm
                                    visible: popupBodyText.visible && (popupBodyText.truncated || popupBodyText.wasTruncated)

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: notifCard.bodyExpanded = !notifCard.bodyExpanded
                                    }
                                }

                                // Action buttons row
                                Flow {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Style.spaceSm
                                    spacing: Style.spaceSm
                                    visible: notifCard.modelData.actions.length > 0

                                    Repeater {
                                        model: notifCard.modelData.actions

                                        delegate: Rectangle {
                                            required property var modelData
                                            required property int index

                                            implicitWidth: actionLabel.implicitWidth + Style.spaceLg * 2
                                            implicitHeight: actionLabel.implicitHeight + Style.spaceSm * 2
                                            radius: Style.radiusFull
                                            color: actionBtnArea.containsMouse ? Style.accentPink : "transparent"
                                            border.width: 1
                                            border.color: Style.accentPink

                                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                                            StyledText {
                                                id: actionLabel
                                                anchors.centerIn: parent
                                                text: modelData.text || ""
                                                color: actionBtnArea.containsMouse ? Style.bgPrimary : Style.accentPink
                                                font.pixelSize: Style.fontSizeSm

                                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                                            }

                                            MouseArea {
                                                id: actionBtnArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    NotificationManager.invokeAction(notifCard.modelData, index)
                                                    NotificationManager.dismissPopupById(notifCard.modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Auto-dismiss popup — always dismiss from popup after timeout
                        Timer {
                            interval: notifCard.modelData.timeout || 5000
                            running: true
                            onTriggered: {
                                if (notifCard.modelData.hasTimeout)
                                    NotificationManager.removeById(notifCard.modelData.id)
                                else
                                    NotificationManager.dismissPopupById(notifCard.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
