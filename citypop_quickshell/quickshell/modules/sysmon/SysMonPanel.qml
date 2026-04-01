pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Singleton"
import "../../common"

Scope {
    Variants {
        model: Quickshell.screens

        DropdownPanel {
            required property var modelData
            screen: modelData

            stateOpen: SysMonState.visible
            stateScreen: SysMonState.screen
            onDismissed: SysMonState.visible = false

            cardWidth: 300
            anchorMode: "top-left"
            showNeonStrip: false

            ColumnLayout {
                anchors.fill: parent
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

                    CloseButton { onClicked: SysMonState.visible = false }
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

                VUMeter {
                    Layout.fillWidth: true
                    value: SysMonState.cpuPercent / 100
                    warnAt: 0.7; critAt: 0.9
                }

                // CPU temperature with mini VU
                RowLayout {
                    spacing: Style.spaceMd

                    MaterialIcon {
                        text: "thermostat"
                        font.pixelSize: 16
                        color: SysMonState.cpuTemp >= 80 ? Style.colorUrgent
                             : SysMonState.cpuTemp >= 60 ? Style.accentAmber
                             : Style.colorGood
                        fill: 1
                    }

                    StyledText {
                        text: SysMonState.cpuTemp + "\u00B0C"
                        font.pixelSize: Style.fontSizeSm
                        font.bold: true
                        color: SysMonState.cpuTemp >= 80 ? Style.colorUrgent
                             : SysMonState.cpuTemp >= 60 ? Style.accentAmber
                             : Style.colorGood

                        Behavior on color { ColorAnimation { duration: Style.animFast } }
                    }

                    VUMeter {
                        Layout.fillWidth: true
                        segments: 10; segmentHeight: 6; segmentSpacing: 1
                        value: SysMonState.cpuTemp / 100
                        baseColor: Style.colorGood; warnAt: 0.6; critAt: 0.8
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

                    VUMeter {
                        Layout.fillWidth: true
                        segments: 10; segmentHeight: 6; segmentSpacing: 1
                        value: Math.min(1.0, SysMonState.fanRpm / 5000)
                        baseColor: Style.textSecondary; warnAt: 0.4; critAt: 0.7
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

                VUMeter {
                    Layout.fillWidth: true
                    value: SysMonState.gpuPercent / 100
                    warnAt: 0.7; critAt: 0.9
                }

                // GPU temperature with mini VU
                RowLayout {
                    spacing: Style.spaceMd

                    MaterialIcon {
                        text: "thermostat"
                        font.pixelSize: 16
                        color: SysMonState.gpuTemp >= 80 ? Style.colorUrgent
                             : SysMonState.gpuTemp >= 60 ? Style.accentAmber
                             : Style.colorGood
                        fill: 1
                    }

                    StyledText {
                        text: SysMonState.gpuTemp + "\u00B0C"
                        font.pixelSize: Style.fontSizeSm
                        font.bold: true
                        color: SysMonState.gpuTemp >= 80 ? Style.colorUrgent
                             : SysMonState.gpuTemp >= 60 ? Style.accentAmber
                             : Style.colorGood

                        Behavior on color { ColorAnimation { duration: Style.animFast } }
                    }

                    VUMeter {
                        Layout.fillWidth: true
                        segments: 10; segmentHeight: 6; segmentSpacing: 1
                        value: SysMonState.gpuTemp / 100
                        baseColor: Style.colorGood; warnAt: 0.6; critAt: 0.8
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

                VUMeter {
                    Layout.fillWidth: true
                    value: SysMonState.ramPercent / 100
                    baseColor: Style.accentPurple; warnAt: 0.7; critAt: 0.9
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
                    id: procHeaders
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

                // Track hovered PID so hover persists across Repeater rebuilds
                property int hoveredPid: -1

                // Process list
                Repeater {
                    model: SysMonState.topProcesses

                    Rectangle {
                        id: procRow
                        required property var modelData
                        required property int index

                        readonly property bool isHovered: procHover.containsMouse || killHover.containsMouse || parent.hoveredPid === modelData.pid

                        Layout.fillWidth: true
                        implicitHeight: procContent.implicitHeight + Style.spaceSm * 2
                        radius: Style.radiusSm
                        color: isHovered ? Style.pinkHover
                             : index % 2 === 1 ? Qt.rgba(Style.bgTertiary.r, Style.bgTertiary.g, Style.bgTertiary.b, 0.3)
                             : "transparent"

                        Behavior on color { ColorAnimation { duration: Style.animFast } }

                        MouseArea {
                            id: procHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onContainsMouseChanged: {
                                if (containsMouse)
                                    procRow.parent.hoveredPid = procRow.modelData.pid
                                else if (procRow.parent.hoveredPid === procRow.modelData.pid)
                                    procRow.parent.hoveredPid = -1
                            }
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
                                color: procRow.isHovered ? Style.textPrimary : Style.textSecondary
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
                                visible: !killBtn.visible
                            }

                            // Kill button (appears on hover)
                            Rectangle {
                                id: killBtn
                                visible: procRow.isHovered && procRow.modelData.pid > 0
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                radius: Style.radiusFull
                                color: killHover.containsMouse ? Style.urgentBg : "transparent"
                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "close"
                                    font.pixelSize: 14
                                    color: killHover.containsMouse ? Style.colorUrgent : Style.textDimmed
                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                }

                                MouseArea {
                                    id: killHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onContainsMouseChanged: {
                                        if (containsMouse)
                                            procRow.parent.hoveredPid = procRow.modelData.pid
                                        else if (procRow.parent.hoveredPid === procRow.modelData.pid)
                                            procRow.parent.hoveredPid = -1
                                    }
                                    onClicked: SysMonState.killProcess(procRow.modelData.pid)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
