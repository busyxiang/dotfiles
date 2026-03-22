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

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Math.round(Style.spaceMd * sf)

        MaterialIcon {
            text: "monitor_heart"
            font.pixelSize: Math.round(16 * sf)
            color: Style.accentPink
            fill: 0
        }

        StyledText {
            text: SysMonState.cpuPercent + "%"
            font.pixelSize: Math.round(Style.fontSizeSm * sf)
        }

        StyledText {
            text: "\u00B7"
            color: Style.textDimmed
            font.pixelSize: Math.round(Style.fontSizeSm * sf)
        }

        StyledText {
            text: SysMonState.cpuTemp + "\u00B0C"
            font.pixelSize: Math.round(Style.fontSizeSm * sf)
            color: SysMonState.cpuTemp >= 85 ? Style.colorUrgent
                 : SysMonState.cpuTemp >= 70 ? Style.accentAmber
                 : Style.accentPink

            Behavior on color { ColorAnimation { duration: Style.animFast } }
        }

        StyledText {
            text: "\u00B7"
            color: Style.textDimmed
            font.pixelSize: Math.round(Style.fontSizeSm * sf)
        }

        MaterialIcon {
            text: "developer_board"
            font.pixelSize: Math.round(14 * sf)
            color: Style.accentAmber
            fill: 0
        }

        StyledText {
            text: SysMonState.gpuPercent + "%"
            font.pixelSize: Math.round(Style.fontSizeSm * sf)
            color: Style.accentAmber
        }

        StyledText {
            text: "\u00B7"
            color: Style.textDimmed
            font.pixelSize: Math.round(Style.fontSizeSm * sf)
        }

        StyledText {
            text: SysMonState.ramUsed + "/" + SysMonState.ramTotal + "G"
            font.pixelSize: Math.round(Style.fontSizeSm * sf)
            color: Style.textSecondary
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
