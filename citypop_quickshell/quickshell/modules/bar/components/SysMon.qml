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

    function cpuColor(pct) {
        if (pct >= 90) return Style.colorUrgent
        if (pct >= 70) return Style.accentAmber
        return Style.accentPink
    }

    function tempColor(temp) {
        if (temp >= 85) return Style.colorUrgent
        if (temp >= 70) return Style.accentAmber
        return Style.accentPink
    }

    function gpuColor(pct) {
        if (pct >= 90) return Style.colorUrgent
        if (pct >= 70) return Style.accentAmber
        return Style.accentPink
    }

    function ramColor(pct) {
        if (pct >= 90) return Style.colorUrgent
        if (pct >= 70) return Style.accentAmber
        return Style.accentPurple
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
                    color: root.cpuColor(SysMonState.cpuPercent)
                    fill: 0

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }

                StyledText {
                    text: SysMonState.cpuPercent + "%"
                    font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
                    color: root.cpuColor(SysMonState.cpuPercent)

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
                    color: root.cpuColor(SysMonState.cpuPercent)

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
                    color: root.gpuColor(SysMonState.gpuPercent)
                    fill: 0

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }

                StyledText {
                    text: SysMonState.gpuPercent + "%"
                    font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
                    color: root.gpuColor(SysMonState.gpuPercent)

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
                    color: root.gpuColor(SysMonState.gpuPercent)

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
                    color: root.ramColor(SysMonState.ramPercent)
                    fill: 0

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }

                StyledText {
                    text: SysMonState.ramUsed + "/" + SysMonState.ramTotal + "G"
                    font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
                    color: root.ramColor(SysMonState.ramPercent)

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            SysMonState.screen = root.screen
            SysMonState.visible = !SysMonState.visible
        }
    }
}
