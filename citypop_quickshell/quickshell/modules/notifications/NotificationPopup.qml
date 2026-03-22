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

                        Layout.fillWidth: true
                        implicitHeight: notifContent.implicitHeight + Style.spaceLg * 2
                        color: Style.bgSecondary
                        radius: Style.radiusMd
                        border.width: 1
                        border.color: Style.bgTertiary

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

                                    StyledText {
                                        text: notifCard.modelData.appName || "Notification"
                                        color: Style.accentPink
                                        font.pixelSize: Style.fontSizeMd
                                        font.bold: true
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

                                StyledText {
                                    text: notifCard.modelData.body || ""
                                    color: Style.textSecondary
                                    font.pixelSize: Style.fontSizeMd
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    visible: text !== ""
                                }
                            }
                        }

                        // Auto-dismiss popup (and history if notification has explicit timeout)
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
