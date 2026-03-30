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
            id: tipPanel
            required property var modelData
            screen: modelData
            visible: tipCard.opacity > 0 && WorkspacePreview.tooltipScreen === modelData
            color: "transparent"
            focusable: false

            anchors { top: true; left: true; right: true }
            readonly property real sf: modelData.height / 1080
            margins.top: Math.round(Style.barHeight * tipPanel.sf)
            implicitHeight: Math.round(Style.spaceMd * tipPanel.sf) + 200
            exclusionMode: ExclusionMode.Ignore

            Item {
                id: tipCard
                x: Math.max(Style.spaceMd, Math.min(
                    WorkspacePreview.tooltipX - width / 2,
                    tipPanel.width - width - Style.spaceMd
                ))
                y: Math.round(Style.spaceMd * tipPanel.sf)
                width: previewContent.implicitWidth + Style.spaceXl * 2
                height: previewContent.implicitHeight + Style.spaceLg * 2

                opacity: WorkspacePreview.tooltipVisible ? 1 : 0
                scale: WorkspacePreview.tooltipVisible ? 1.0 : 0.92

                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                // Card background
                Rectangle {
                    anchors.fill: parent
                    radius: Style.radiusMd
                    color: Style.bgSecondary
                    border.width: 1
                    border.color: Style.bgTertiary

                    NeonStrip {}
                }

                // Arrow pointer
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: -4
                    width: 10; height: 10
                    rotation: 45
                    color: Style.bgSecondary
                    border.width: 1
                    border.color: Style.bgTertiary
                    z: 1
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0
                    width: 14; height: 6
                    color: Style.bgSecondary
                    z: 2
                }

                ColumnLayout {
                    id: previewContent
                    anchors.centerIn: parent
                    spacing: Style.spaceSm

                    // Workspace label
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Workspace " + WorkspacePreview.hoveredWsId
                        font.pixelSize: Style.fontSizeSm
                        font.bold: true
                        color: Style.textPrimary
                    }

                    // Mini monitor with window rectangles
                    Item {
                        id: miniMonitor
                        readonly property real previewW: 200
                        readonly property real previewH: WorkspacePreview.monitorW > 0
                            ? previewW * (WorkspacePreview.monitorH / WorkspacePreview.monitorW)
                            : 112
                        readonly property real scaleFactor: WorkspacePreview.monitorW > 0
                            ? previewW / WorkspacePreview.monitorW
                            : 0.1

                        Layout.preferredWidth: previewW
                        Layout.preferredHeight: previewH
                        Layout.alignment: Qt.AlignHCenter

                        // Monitor background
                        Rectangle {
                            anchors.fill: parent
                            radius: Style.radiusSm
                            color: Style.bgPrimary
                            border.width: 1
                            border.color: Style.bgTertiary
                        }

                        // Empty state
                        StyledText {
                            anchors.centerIn: parent
                            text: "Empty"
                            font.pixelSize: 11
                            color: Style.textDimmed
                            visible: WorkspacePreview.previewClients.length === 0
                        }

                        // Window rectangles
                        Repeater {
                            model: WorkspacePreview.previewClients

                            Rectangle {
                                required property var modelData
                                required property int index

                                readonly property real sf: miniMonitor.scaleFactor

                                x: Math.max(0, Math.round(modelData.x * sf))
                                y: Math.max(0, Math.round(modelData.y * sf))
                                width: Math.min(Math.round(modelData.w * sf), miniMonitor.previewW - x)
                                height: Math.min(Math.round(modelData.h * sf), miniMonitor.previewH - y)
                                radius: 2
                                color: Style.bgTertiary
                                border.width: 1
                                border.color: Style.pinkBorder

                                // App icon
                                Image {
                                    anchors.centerIn: parent
                                    width: Math.min(24, parent.width - 4, parent.height - 4)
                                    height: width
                                    source: modelData.icon
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    visible: modelData.icon !== "" && status === Image.Ready
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                }

                                // Fallback: class abbreviation
                                StyledText {
                                    anchors.centerIn: parent
                                    text: modelData.cls.substring(0, 4)
                                    font.pixelSize: 9
                                    color: Style.textDimmed
                                    visible: modelData.icon === ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
