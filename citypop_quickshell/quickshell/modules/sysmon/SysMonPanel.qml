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
                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "monitor_heart"
                            font.pixelSize: 20
                            color: Style.accentPink
                            fill: 1
                        }

                        StyledText {
                            text: "System Monitor"
                            font.pixelSize: Style.fontSizeXl
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        // Close
                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Style.radiusFull
                            color: closeHover.containsMouse ? Style.bgTertiary : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "close"
                                font.pixelSize: 16
                                color: closeHover.containsMouse ? Style.textPrimary : Style.textDimmed
                            }

                            MouseArea {
                                id: closeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SysMonState.visible = false
                            }
                        }
                    }

                    // ── Neon divider ──
                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Style.accentPink
                        opacity: 0.6
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

                    // CPU VU meter
                    Row {
                        spacing: 2
                        Layout.fillWidth: true

                        Repeater {
                            model: 20

                            Rectangle {
                                required property int index
                                property bool isLit: SysMonState.cpuPercent > index * 5

                                width: (parent.width - 19 * parent.spacing) / 20
                                height: 8
                                radius: 1
                                color: isLit ? (SysMonState.cpuPercent >= 90 ? Style.colorUrgent
                                             : SysMonState.cpuPercent >= 70 ? Style.accentAmber
                                             : Style.accentPink)
                                      : Style.bgTertiary

                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                            }
                        }
                    }

                    // CPU temperature with mini VU
                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "thermostat"
                            font.pixelSize: 16
                            color: SysMonState.cpuTemp >= 80 ? Style.colorUrgent
                                 : SysMonState.cpuTemp >= 60 ? Style.accentAmber
                                 : "#66bb6a"
                            fill: 1
                        }

                        StyledText {
                            text: SysMonState.cpuTemp + "\u00B0C"
                            font.pixelSize: Style.fontSizeSm
                            font.bold: true
                            color: SysMonState.cpuTemp >= 80 ? Style.colorUrgent
                                 : SysMonState.cpuTemp >= 60 ? Style.accentAmber
                                 : "#66bb6a"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                        }

                        // Temp VU meter (10 segments, 0-100°C)
                        Row {
                            spacing: 1
                            Layout.fillWidth: true

                            Repeater {
                                model: 10

                                Rectangle {
                                    required property int index
                                    property bool isLit: SysMonState.cpuTemp > index * 10

                                    width: (parent.width - 9 * parent.spacing) / 10
                                    height: 6
                                    radius: 1
                                    color: isLit ? (index >= 8 ? Style.colorUrgent
                                                 : index >= 6 ? Style.accentAmber
                                                 : "#66bb6a")
                                          : Style.bgTertiary

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                }
                            }
                        }
                    }

                    // Fan speed with mini VU (only shown when fanRpm > 0)
                    RowLayout {
                        spacing: Style.spaceMd
                        visible: SysMonState.fanRpm > 0

                        MaterialIcon {
                            text: "mode_fan"
                            font.pixelSize: 16
                            color: SysMonState.fanRpm >= 3500 ? Style.colorUrgent
                                 : SysMonState.fanRpm >= 2000 ? Style.accentAmber
                                 : Style.textSecondary
                            fill: 1

                            RotationAnimation on rotation {
                                running: SysMonState.fanRpm > 0
                                from: 0; to: 360
                                duration: SysMonState.fanRpm > 2000 ? 2000 : 4000
                                loops: Animation.Infinite
                            }
                        }

                        StyledText {
                            text: SysMonState.fanRpm.toLocaleString() + " RPM"
                            font.pixelSize: Style.fontSizeSm
                            font.bold: true
                            color: SysMonState.fanRpm >= 3500 ? Style.colorUrgent
                                 : SysMonState.fanRpm >= 2000 ? Style.accentAmber
                                 : Style.textPrimary

                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                        }

                        // Fan VU meter (10 segments, 0-5000 RPM)
                        Row {
                            spacing: 1
                            Layout.fillWidth: true

                            Repeater {
                                model: 10

                                Rectangle {
                                    required property int index
                                    property bool isLit: SysMonState.fanRpm > index * 500

                                    width: (parent.width - 9 * parent.spacing) / 10
                                    height: 6
                                    radius: 1
                                    color: isLit ? (index >= 7 ? Style.colorUrgent
                                                 : index >= 4 ? Style.accentAmber
                                                 : Style.textSecondary)
                                          : Style.bgTertiary

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Style.accentPink
                        opacity: 0.3
                    }

                    // ═══════════════════════════════════
                    // GPU Section
                    // ═══════════════════════════════════

                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "developer_board"
                            font.pixelSize: 20
                            color: Style.accentPink
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

                    // GPU VU meter
                    Row {
                        spacing: 2
                        Layout.fillWidth: true

                        Repeater {
                            model: 20

                            Rectangle {
                                required property int index
                                property bool isLit: SysMonState.gpuPercent > index * 5

                                width: (parent.width - 19 * parent.spacing) / 20
                                height: 8
                                radius: 1
                                color: isLit ? (SysMonState.gpuPercent >= 90 ? Style.colorUrgent
                                             : SysMonState.gpuPercent >= 70 ? Style.accentAmber
                                             : Style.accentPink)
                                      : Style.bgTertiary

                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                            }
                        }
                    }

                    // GPU temperature with mini VU
                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "thermostat"
                            font.pixelSize: 16
                            color: SysMonState.gpuTemp >= 80 ? Style.colorUrgent
                                 : SysMonState.gpuTemp >= 60 ? Style.accentAmber
                                 : "#66bb6a"
                            fill: 1
                        }

                        StyledText {
                            text: SysMonState.gpuTemp + "\u00B0C"
                            font.pixelSize: Style.fontSizeSm
                            font.bold: true
                            color: SysMonState.gpuTemp >= 80 ? Style.colorUrgent
                                 : SysMonState.gpuTemp >= 60 ? Style.accentAmber
                                 : "#66bb6a"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                        }

                        // Temp VU meter
                        Row {
                            spacing: 1
                            Layout.fillWidth: true

                            Repeater {
                                model: 10

                                Rectangle {
                                    required property int index
                                    property bool isLit: SysMonState.gpuTemp > index * 10

                                    width: (parent.width - 9 * parent.spacing) / 10
                                    height: 6
                                    radius: 1
                                    color: isLit ? (index >= 8 ? Style.colorUrgent
                                                 : index >= 6 ? Style.accentAmber
                                                 : "#66bb6a")
                                          : Style.bgTertiary

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Style.accentPink
                        opacity: 0.3
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
                            text: SysMonState.ramUsed + "G / " + SysMonState.ramTotal + "G"
                            font.pixelSize: Style.fontSizeSm
                            color: Style.textSecondary
                        }

                        StyledText {
                            text: SysMonState.ramPercent + "%"
                            font.pixelSize: Style.fontSizeMd
                            font.bold: true
                            color: SysMonState.ramPercent >= 90 ? Style.colorUrgent
                                 : SysMonState.ramPercent >= 70 ? Style.accentAmber
                                 : Style.textPrimary
                        }
                    }

                    // RAM VU meter
                    Row {
                        spacing: 2
                        Layout.fillWidth: true

                        Repeater {
                            model: 20

                            Rectangle {
                                required property int index
                                property bool isLit: SysMonState.ramPercent > index * 5

                                width: (parent.width - 19 * parent.spacing) / 20
                                height: 8
                                radius: 1
                                color: isLit ? (SysMonState.ramPercent >= 90 ? Style.colorUrgent
                                             : SysMonState.ramPercent >= 70 ? Style.accentAmber
                                             : Style.accentPurple)
                                      : Style.bgTertiary

                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                            }
                        }
                    }

                    // ── Neon divider ──
                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Style.accentPink
                        opacity: 0.4
                    }

                    // ═══════════════════════════════════
                    // Top Processes Section
                    // ═══════════════════════════════════

                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "monitoring"
                            font.pixelSize: 20
                            color: Style.accentPink
                            fill: 1
                        }

                        StyledText {
                            text: "Top Processes"
                            font.pixelSize: Style.fontSizeMd
                            font.bold: true
                        }
                    }

                    // Column headers
                    RowLayout {
                        spacing: Style.spaceSm

                        StyledText {
                            Layout.fillWidth: true
                            text: "Name"
                            font.pixelSize: Style.fontSizeSm
                            color: Style.textDimmed
                        }

                        StyledText {
                            Layout.preferredWidth: 48
                            text: "CPU%"
                            font.pixelSize: Style.fontSizeSm
                            color: Style.textDimmed
                            horizontalAlignment: Text.AlignRight
                        }

                        StyledText {
                            Layout.preferredWidth: 48
                            text: "MEM%"
                            font.pixelSize: Style.fontSizeSm
                            color: Style.textDimmed
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // Process list
                    Repeater {
                        model: SysMonState.topProcesses

                        Rectangle {
                            id: procRow
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: procContent.implicitHeight + Style.spaceSm * 2
                            radius: Style.radiusSm
                            color: procHover.containsMouse ? Qt.rgba(1, 0.41, 0.71, 0.1)
                                 : index % 2 === 1 ? Qt.rgba(Style.bgTertiary.r, Style.bgTertiary.g, Style.bgTertiary.b, 0.3)
                                 : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            MouseArea {
                                id: procHover
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            RowLayout {
                                id: procContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Style.spaceSm
                                spacing: Style.spaceSm

                                StyledText {
                                    Layout.fillWidth: true
                                    text: procRow.modelData.name
                                    font.pixelSize: Style.fontSizeSm
                                    color: procHover.containsMouse ? Style.textPrimary : Style.textSecondary
                                    elide: Text.ElideRight

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                }

                                StyledText {
                                    Layout.preferredWidth: 48
                                    text: procRow.modelData.cpu
                                    font.pixelSize: Style.fontSizeSm
                                    color: parseFloat(procRow.modelData.cpu) >= 50 ? Style.colorUrgent
                                         : parseFloat(procRow.modelData.cpu) >= 20 ? Style.accentAmber
                                         : Style.textSecondary
                                    horizontalAlignment: Text.AlignRight
                                }

                                StyledText {
                                    Layout.preferredWidth: 48
                                    text: procRow.modelData.mem
                                    font.pixelSize: Style.fontSizeSm
                                    color: Style.textSecondary
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
