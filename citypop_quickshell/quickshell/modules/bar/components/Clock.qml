import QtQuick
import QtQuick.Layouts
import "../../../Singleton"
import "../../../common"
import "../../calendar"

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
            text: "schedule"
            font.pixelSize: Math.round(16 * sf)
            color: Style.accentPink
            fill: 0
        }

        StyledText {
            text: Time.time
            font.bold: true
            font.pixelSize: Math.round(Style.fontSizeMd * sf)
        }

        StyledText {
            text: Time.date
            color: Style.textSecondary
            font.pixelSize: Math.round(Style.fontSizeSm * sf)
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            CalendarState.screen = root.screen
            CalendarState.visible = !CalendarState.visible
        }
    }
}
