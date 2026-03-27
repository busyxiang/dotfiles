pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../Singleton"
import "../../../common"
import "../../weather"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    readonly property bool loading: WeatherState.current === null && !WeatherState.fetchError
    readonly property bool retrying: WeatherState.retrying

    // Weather-aware icon color: amber for error, purple for rain, amber for hot, pink default
    readonly property color iconColor: {
        if (WeatherState.fetchError) return Style.accentAmber
        if (!WeatherState.current) return Style.accentPink
        var code = WeatherState.current.weatherCode
        // Rain/drizzle/showers: purple
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return Style.accentPurple
        // Thunderstorm: urgent
        if (code >= 95)
            return Style.colorUrgent
        // Hot: amber
        if (WeatherState.current.temp >= 35)
            return Style.accentAmber
        return Style.accentPink
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // Loading pulse (initial load + retry)
    SequentialAnimation {
        running: root.loading || root.retrying
        loops: Animation.Infinite
        NumberAnimation { target: row; property: "opacity"; from: 1.0; to: 0.3; duration: root.retrying ? 1200 : 600; easing.type: Easing.InOutSine }
        NumberAnimation { target: row; property: "opacity"; from: 0.3; to: 1.0; duration: root.retrying ? 1200 : 600; easing.type: Easing.InOutSine }
        onRunningChanged: { if (!running) row.opacity = 1.0 }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: Math.round(Style.spaceSm * root.sf)

        MaterialIcon {
            text: WeatherState.fetchError ? "cloud_off" : (WeatherState.current ? WeatherState.current.icon : "cloud")
            font.pixelSize: Math.round(16 * root.sf)
            color: root.iconColor
            fill: 1
        }

        StyledText {
            text: WeatherState.fetchError ? "!" : (WeatherState.current ? WeatherState.current.temp + "°" : "—")
            font.pixelSize: Math.round(Style.fontSizeMd * root.sf)
            font.bold: true
            color: WeatherState.fetchError ? Style.accentAmber : Style.textPrimary
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onContainsMouseChanged: {
            if (containsMouse && WeatherState.current && !WeatherState.visible) {
                var globalPos = root.mapToItem(null, root.width / 2, 0)
                WeatherState.tooltipX = globalPos.x
                WeatherState.tooltipScreen = root.screen
                WeatherState.tooltipVisible = true
            } else {
                WeatherState.tooltipVisible = false
            }
        }

        onClicked: {
            WeatherState.tooltipVisible = false
            var wasOpen = WeatherState.visible
            PanelManager.closeAll()
            if (!wasOpen) {
                WeatherState.screen = root.screen
                WeatherState.visible = true
            }
        }
    }
}
