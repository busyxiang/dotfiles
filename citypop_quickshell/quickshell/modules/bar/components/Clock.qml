import QtQuick
import QtQuick.Layouts
import "../../../Singleton"
import "../../../common"

RowLayout {
    property real sf: 1.0

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
