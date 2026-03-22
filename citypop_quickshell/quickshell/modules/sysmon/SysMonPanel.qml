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
            id: panel
            required property var modelData
            screen: modelData
            visible: SysMonState.visible && SysMonState.screen === modelData
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore

            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: Style.barHeight
                onClicked: SysMonState.visible = false
            }

            // --- Dropdown Card ---
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: Style.barHeight + Style.spaceMd
                anchors.leftMargin: Style.spaceMd
                width: 300
                height: cardContent.implicitHeight + Style.spaceXl * 2
                color: Style.bgSecondary
                radius: Style.radiusLg
                border.width: 1
                border.color: Style.bgTertiary

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: Style.spaceXl
                    spacing: Style.spaceLg

                    // ── Header ──
                    StyledText {
                        text: "System Monitor"
                        font.pixelSize: Style.fontSizeXl
                        font.bold: true
                        color: Style.accentPink
                    }

                    // ── Divider ──
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Style.bgTertiary
                    }

                    // ═══════════════════════════════════
                    // CPU Section
                    // ═══════════════════════════════════

                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "memory"
                            font.pixelSize: 20
                            color: Style.accentPink
                            fill: 1
                        }

                        StyledText {
                            text: "CPU"
                            font.pixelSize: Style.fontSizeMd
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: SysMonState.cpuPercent + "%"
                            font.pixelSize: Style.fontSizeMd
                            font.bold: true
                            color: SysMonState.cpuPercent >= 90 ? Style.colorUrgent
                                 : SysMonState.cpuPercent >= 70 ? Style.accentAmber
                                 : Style.textPrimary
                        }
                    }

                    // CPU usage bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Style.bgTertiary

                        Rectangle {
                            width: Math.min(parent.width * SysMonState.cpuPercent / 100, parent.width)
                            height: parent.height
                            radius: parent.radius
                            color: SysMonState.cpuPercent >= 90 ? Style.colorUrgent
                                 : SysMonState.cpuPercent >= 70 ? Style.accentAmber
                                 : Style.accentPink

                            Behavior on width { NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                        }
                    }

                    // CPU temperature
                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "thermostat"
                            font.pixelSize: 18
                            color: SysMonState.cpuTemp >= 80 ? Style.colorUrgent
                                 : SysMonState.cpuTemp >= 60 ? Style.accentAmber
                                 : "#66bb6a"
                            fill: 1
                        }

                        StyledText {
                            text: "Temperature"
                            color: Style.textSecondary
                            font.pixelSize: Style.fontSizeSm
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: SysMonState.cpuTemp + "\u00B0C"
                            font.pixelSize: Style.fontSizeSm
                            font.bold: true
                            color: SysMonState.cpuTemp >= 80 ? Style.colorUrgent
                                 : SysMonState.cpuTemp >= 60 ? Style.accentAmber
                                 : "#66bb6a"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                        }
                    }

                    // ── Divider ──
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Style.bgTertiary
                    }

                    // ═══════════════════════════════════
                    // GPU Section
                    // ═══════════════════════════════════

                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "developer_board"
                            font.pixelSize: 20
                            color: Style.accentAmber
                            fill: 1
                        }

                        StyledText {
                            text: "GPU"
                            font.pixelSize: Style.fontSizeMd
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: SysMonState.gpuPercent + "%"
                            font.pixelSize: Style.fontSizeMd
                            font.bold: true
                            color: SysMonState.gpuPercent >= 90 ? Style.colorUrgent
                                 : SysMonState.gpuPercent >= 70 ? Style.accentAmber
                                 : Style.textPrimary
                        }
                    }

                    // GPU usage bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Style.bgTertiary

                        Rectangle {
                            width: Math.min(parent.width * SysMonState.gpuPercent / 100, parent.width)
                            height: parent.height
                            radius: parent.radius
                            color: SysMonState.gpuPercent >= 90 ? Style.colorUrgent
                                 : SysMonState.gpuPercent >= 70 ? Style.accentAmber
                                 : Style.accentAmber

                            Behavior on width { NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                        }
                    }

                    // GPU temperature
                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "thermostat"
                            font.pixelSize: 18
                            color: SysMonState.gpuTemp >= 80 ? Style.colorUrgent
                                 : SysMonState.gpuTemp >= 60 ? Style.accentAmber
                                 : "#66bb6a"
                            fill: 1
                        }

                        StyledText {
                            text: "Temperature"
                            color: Style.textSecondary
                            font.pixelSize: Style.fontSizeSm
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: SysMonState.gpuTemp + "\u00B0C"
                            font.pixelSize: Style.fontSizeSm
                            font.bold: true
                            color: SysMonState.gpuTemp >= 80 ? Style.colorUrgent
                                 : SysMonState.gpuTemp >= 60 ? Style.accentAmber
                                 : "#66bb6a"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                        }
                    }

                    // ── Divider ──
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Style.bgTertiary
                    }

                    // ═══════════════════════════════════
                    // RAM Section
                    // ═══════════════════════════════════

                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "memory_alt"
                            font.pixelSize: 20
                            color: Style.accentPurple
                            fill: 1
                        }

                        StyledText {
                            text: "RAM"
                            font.pixelSize: Style.fontSizeMd
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: SysMonState.ramPercent + "%"
                            font.pixelSize: Style.fontSizeMd
                            font.bold: true
                            color: SysMonState.ramPercent >= 90 ? Style.colorUrgent
                                 : SysMonState.ramPercent >= 70 ? Style.accentAmber
                                 : Style.textPrimary
                        }
                    }

                    // RAM usage bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Style.bgTertiary

                        Rectangle {
                            width: Math.min(parent.width * SysMonState.ramPercent / 100, parent.width)
                            height: parent.height
                            radius: parent.radius
                            color: SysMonState.ramPercent >= 90 ? Style.colorUrgent
                                 : SysMonState.ramPercent >= 70 ? Style.accentAmber
                                 : Style.accentPurple

                            Behavior on width { NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                        }
                    }

                    // RAM detail text
                    StyledText {
                        text: SysMonState.ramUsed + "G / " + SysMonState.ramTotal + "G"
                        color: Style.textSecondary
                        font.pixelSize: Style.fontSizeSm
                    }
                }
            }
        }
    }
}
