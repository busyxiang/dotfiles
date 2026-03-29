pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../Singleton"
import "../../../common"
import "../../sysmon"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    function thresholdColor(value, warn, crit, base) {
        if (value >= crit) return Style.colorUrgent
        if (value >= warn) return Style.accentAmber
        return base ?? Style.accentPink
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Math.round(Style.spaceSm * sf)

        // ── CPU pill ──
        Rectangle {
            implicitWidth: cpuRow.implicitWidth + Math.round(Style.spaceMd * root.sf) * 2
            implicitHeight: Math.round(22 * root.sf)
            radius: Style.radiusFull
            color: Style.bgTertiary

            RowLayout {
                id: cpuRow
                anchors.centerIn: parent
                spacing: Math.round(Style.spaceSm * root.sf)

                MaterialIcon {
                    text: "memory"
                    font.pixelSize: Math.round(14 * root.sf)
                    color: root.thresholdColor(SysMonState.cpuPercent, 70, 90)
                    fill: 0

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }

                StyledText {
                    text: SysMonState.cpuPercent + "%"
                    font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
                    color: root.thresholdColor(SysMonState.cpuPercent, 70, 90)

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: Math.round(10 * root.sf)
                    color: Style.textDimmed
                    opacity: 0.4
                }

                StyledText {
                    text: SysMonState.cpuTemp + "\u00B0"
                    font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
                    color: root.thresholdColor(SysMonState.cpuTemp, 60, 80)

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }
            }
        }

        // ── GPU pill ──
        Rectangle {
            implicitWidth: gpuRow.implicitWidth + Math.round(Style.spaceMd * root.sf) * 2
            implicitHeight: Math.round(22 * root.sf)
            radius: Style.radiusFull
            color: Style.bgTertiary

            RowLayout {
                id: gpuRow
                anchors.centerIn: parent
                spacing: Math.round(Style.spaceSm * root.sf)

                MaterialIcon {
                    text: "developer_board"
                    font.pixelSize: Math.round(14 * root.sf)
                    color: root.thresholdColor(SysMonState.gpuPercent, 70, 90)
                    fill: 0

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }

                StyledText {
                    text: SysMonState.gpuPercent + "%"
                    font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
                    color: root.thresholdColor(SysMonState.gpuPercent, 70, 90)

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: Math.round(10 * root.sf)
                    color: Style.textDimmed
                    opacity: 0.4
                }

                StyledText {
                    text: SysMonState.gpuTemp + "\u00B0"
                    font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
                    color: root.thresholdColor(SysMonState.gpuTemp, 60, 80)

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }
            }
        }

        // ── RAM pill ──
        Rectangle {
            implicitWidth: ramRow.implicitWidth + Math.round(Style.spaceMd * root.sf) * 2
            implicitHeight: Math.round(22 * root.sf)
            radius: Style.radiusFull
            color: Style.bgTertiary

            RowLayout {
                id: ramRow
                anchors.centerIn: parent
                spacing: Math.round(Style.spaceSm * root.sf)

                MaterialIcon {
                    text: "memory_alt"
                    font.pixelSize: Math.round(14 * root.sf)
                    color: root.thresholdColor(SysMonState.ramPercent, 70, 90, Style.accentPurple)
                    fill: 0

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }

                StyledText {
                    text: SysMonState.ramUsed + "/" + SysMonState.ramTotal + "G"
                    font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
                    color: root.thresholdColor(SysMonState.ramPercent, 70, 90, Style.accentPurple)

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var wasOpen = SysMonState.visible
            PanelManager.closeAll()
            if (!wasOpen) {
                SysMonState.screen = root.screen
                SysMonState.visible = true
            }
        }
    }
}
