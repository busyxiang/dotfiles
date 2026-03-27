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
            readonly property real sf: modelData.height / 1080
            property bool _open: WeatherState.visible && WeatherState.screen === modelData
            visible: WeatherState.visible || card.opacity > 0
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore
            margins.top: Math.round(Style.barHeight * panel.sf)

            MouseArea {
                anchors.fill: parent
                onClicked: WeatherState.visible = false
            }

            // --- Dropdown Card ---
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Math.round(Style.spaceMd * panel.sf)
                anchors.rightMargin: Math.round((Style.spaceMd + 90) * panel.sf)
                width: 340
                height: cardContent.implicitHeight + Style.spaceXl * 2
                color: Style.bgSecondary
                radius: Style.radiusLg
                border.width: 1
                border.color: Style.bgTertiary

                opacity: panel._open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: panel._open ? 0 : -8
                    Behavior on y { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                }

                NeonStrip {}

                MouseArea { anchors.fill: parent }

                // Refresh button (floating top-right, next to close)
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: closeBtn.left
                    anchors.topMargin: Style.spaceMd
                    anchors.rightMargin: Style.spaceSm
                    z: 2
                    width: 28; height: 28
                    radius: Style.radiusFull
                    color: refreshHover.containsMouse ? Style.bgTertiary : "transparent"
                    Behavior on color { ColorAnimation { duration: Style.animFast } }

                    MaterialIcon {
                        id: refreshIcon
                        anchors.centerIn: parent
                        text: "refresh"
                        font.pixelSize: 16
                        color: refreshHover.containsMouse ? Style.textPrimary : Style.textDimmed
                    }

                    RotationAnimation {
                        id: refreshSpin
                        target: refreshIcon
                        from: 0; to: 360
                        duration: 600
                        easing.type: Easing.InOutCubic
                    }

                    MouseArea {
                        id: refreshHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            refreshSpin.start()
                            WeatherState._retryCount = 0
                            WeatherState.retrying = false
                            WeatherState.fetchAll()
                        }
                    }
                }

                CloseButton {
                    id: closeBtn
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: Style.spaceMd
                    anchors.rightMargin: Style.spaceMd
                    z: 2
                    onClicked: WeatherState.visible = false
                }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: Style.spaceXl
                    spacing: Style.spaceLg

                    // --- Location switch crossfade ---
                    property int _prevLocation: 0
                    property real contentOpacity: 1.0

                    Connections {
                        target: WeatherState
                        function onActiveLocationChanged() {
                            if (WeatherState.activeLocation !== cardContent._prevLocation) {
                                cardContent._prevLocation = WeatherState.activeLocation
                                fadeOut.start()
                            }
                        }
                    }

                    SequentialAnimation {
                        id: fadeOut
                        NumberAnimation {
                            target: cardContent; property: "contentOpacity"
                            to: 0; duration: 100; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: cardContent; property: "contentOpacity"
                            to: 1; duration: 200; easing.type: Easing.OutCubic
                        }
                    }

                    // --- Location Tabs ---
                    RowLayout {
                        spacing: Style.spaceSm

                        Repeater {
                            model: WeatherState.locations

                            Rectangle {
                                id: locTab
                                required property var modelData
                                required property int index
                                readonly property bool active: WeatherState.activeLocation === index

                                implicitWidth: locLabel.implicitWidth + Style.spaceXl * 2
                                implicitHeight: 28
                                radius: Style.radiusFull
                                color: active ? Style.accentPink : locHover.containsMouse ? Style.bgTertiary : "transparent"
                                border.width: active ? 0 : 1
                                border.color: Style.bgTertiary

                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                StyledText {
                                    id: locLabel
                                    anchors.centerIn: parent
                                    text: locTab.modelData.name
                                    font.pixelSize: Style.fontSizeSm
                                    font.bold: locTab.active
                                    color: locTab.active ? Style.bgPrimary : Style.textSecondary
                                }

                                MouseArea {
                                    id: locHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: WeatherState.activeLocation = locTab.index
                                }
                            }
                        }
                    }

                    // --- Neon Divider ---
                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Style.accentPink
                        opacity: 0.6 * cardContent.contentOpacity
                    }

                    // --- Current Conditions Hero ---
                    RowLayout {
                        spacing: Style.spaceLg
                        visible: WeatherState.current !== null
                        opacity: cardContent.contentOpacity

                        MaterialIcon {
                            text: WeatherState.current ? WeatherState.current.icon : "cloud"
                            font.pixelSize: 48
                            color: Style.accentPink
                            fill: 1
                        }

                        ColumnLayout {
                            spacing: Style.spaceXs

                            StyledText {
                                text: WeatherState.current ? WeatherState.current.temp + "°C" : "—"
                                font.pixelSize: 36
                                font.bold: true
                                color: Style.textPrimary
                            }

                            StyledText {
                                text: WeatherState.current ? WeatherState.current.description : ""
                                font.pixelSize: Style.fontSizeMd
                                color: Style.textSecondary
                            }

                            StyledText {
                                text: {
                                    if (!WeatherState.current) return ""
                                    var c = WeatherState.current
                                    return "Feels " + c.feelsLike + "°  ·  H:" + c.high + "°  L:" + c.low + "°"
                                }
                                font.pixelSize: Style.fontSizeSm
                                color: Style.textDimmed
                            }
                        }
                    }

                    // --- No data / Error state ---
                    ColumnLayout {
                        visible: WeatherState.current === null
                        spacing: Style.spaceMd
                        opacity: cardContent.contentOpacity

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: WeatherState.fetchError ? "cloud_off" : "cloud"
                            font.pixelSize: 36
                            color: WeatherState.fetchError ? Style.accentAmber : Style.textDimmed
                            fill: 1
                            visible: WeatherState.fetchError || !WeatherState.retrying
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                if (WeatherState.fetchError) return "Failed to fetch weather data"
                                if (WeatherState.retrying) return "Retrying in " + Math.ceil(WeatherState._retryDelays[WeatherState._retryCount - 1] / 60000) + "m… (attempt " + WeatherState._retryCount + "/" + WeatherState._maxRetries + ")"
                                return "Fetching weather data…"
                            }
                            color: WeatherState.fetchError ? Style.accentAmber : Style.textDimmed
                            font.pixelSize: Style.fontSizeMd
                        }

                        // Retry button
                        Rectangle {
                            visible: WeatherState.fetchError
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: weatherRetryRow.implicitWidth + Style.spaceXl * 2
                            implicitHeight: 28
                            radius: Style.radiusFull
                            color: weatherRetryHover.containsMouse ? Style.bgTertiary : "transparent"
                            border.width: 1
                            border.color: Style.accentPink

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            RowLayout {
                                id: weatherRetryRow
                                anchors.centerIn: parent
                                spacing: Style.spaceSm

                                MaterialIcon {
                                    text: "refresh"
                                    font.pixelSize: 14
                                    color: Style.accentPink
                                    fill: 0
                                }
                                StyledText {
                                    text: "Retry"
                                    font.pixelSize: Style.fontSizeSm
                                    color: Style.accentPink
                                }
                            }

                            MouseArea {
                                id: weatherRetryHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    WeatherState._retryCount = 0
                                    WeatherState.fetchAll()
                                }
                            }
                        }
                    }

                    // --- Details Grid (2x2) ---
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Style.spaceSm
                        rowSpacing: Style.spaceSm
                        visible: WeatherState.current !== null
                        opacity: cardContent.contentOpacity

                        // Humidity
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            implicitHeight: humCol.implicitHeight + Style.spaceLg * 2
                            radius: Style.radiusMd
                            color: Style.bgTertiary

                            ColumnLayout {
                                id: humCol
                                anchors.centerIn: parent
                                spacing: Style.spaceXs

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "humidity_percentage"
                                    font.pixelSize: 20
                                    color: Style.accentPink
                                    fill: 1
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: WeatherState.current ? WeatherState.current.humidity + "%" : ""
                                    font.pixelSize: Style.fontSizeSm
                                    font.bold: true
                                    color: Style.textPrimary
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Humidity"
                                    font.pixelSize: 11
                                    color: Style.textDimmed
                                }
                            }
                        }

                        // Wind
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            implicitHeight: windCol.implicitHeight + Style.spaceLg * 2
                            radius: Style.radiusMd
                            color: Style.bgTertiary

                            ColumnLayout {
                                id: windCol
                                anchors.centerIn: parent
                                spacing: Style.spaceXs

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 20; implicitHeight: 20

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "navigation"
                                        font.pixelSize: 20
                                        color: Style.accentPink
                                        fill: 1
                                        rotation: WeatherState.current ? WeatherState.current.windDirection : 0
                                    }
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: {
                                        if (!WeatherState.current) return ""
                                        var c = WeatherState.current
                                        return WeatherState.windCardinal(c.windDirection) + " " + c.windSpeed + " km/h"
                                    }
                                    font.pixelSize: Style.fontSizeSm
                                    font.bold: true
                                    color: Style.textPrimary
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Wind"
                                    font.pixelSize: 11
                                    color: Style.textDimmed
                                }
                            }
                        }

                        // UV Index
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            implicitHeight: uvCol.implicitHeight + Style.spaceLg * 2
                            radius: Style.radiusMd
                            color: Style.bgTertiary

                            ColumnLayout {
                                id: uvCol
                                anchors.centerIn: parent
                                spacing: Style.spaceXs

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "wb_sunny"
                                    font.pixelSize: 20
                                    color: {
                                        if (!WeatherState.current) return Style.accentPink
                                        var uv = WeatherState.current.uvIndex
                                        return uv >= 8 ? Style.colorUrgent : uv >= 6 ? Style.accentAmber : Style.accentPink
                                    }
                                    fill: 1
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: WeatherState.current ? WeatherState.current.uvIndex : ""
                                    font.pixelSize: Style.fontSizeSm
                                    font.bold: true
                                    color: Style.textPrimary
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "UV Index"
                                    font.pixelSize: 11
                                    color: Style.textDimmed
                                }
                            }
                        }

                        // Sunrise / Sunset
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            implicitHeight: sunCol.implicitHeight + Style.spaceLg * 2
                            radius: Style.radiusMd
                            color: Style.bgTertiary

                            ColumnLayout {
                                id: sunCol
                                anchors.centerIn: parent
                                spacing: Style.spaceXs

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: WeatherState.current && WeatherState.current.isDay ? "wb_twilight" : "nights_stay"
                                    font.pixelSize: 20
                                    color: Style.accentAmber
                                    fill: 1
                                }
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: Style.spaceSm

                                    StyledText {
                                        text: WeatherState.current ? WeatherState.current.sunrise : ""
                                        font.pixelSize: 11
                                        color: Style.textPrimary
                                    }
                                    StyledText {
                                        text: "/"
                                        font.pixelSize: 11
                                        color: Style.textDimmed
                                    }
                                    StyledText {
                                        text: WeatherState.current ? WeatherState.current.sunset : ""
                                        font.pixelSize: 11
                                        color: Style.textPrimary
                                    }
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Rise / Set"
                                    font.pixelSize: 11
                                    color: Style.textDimmed
                                }
                            }
                        }
                    }

                    // --- Neon Divider ---
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Style.bgTertiary
                        visible: WeatherState.current !== null
                        opacity: cardContent.contentOpacity
                    }

                    // --- 5-Day Forecast ---
                    // Hover description label
                    property string hoveredForecastDesc: ""

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.spaceSm
                        visible: WeatherState.current !== null && WeatherState.current.forecast.length > 0
                        opacity: cardContent.contentOpacity

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.spaceSm

                            Repeater {
                                model: WeatherState.current ? WeatherState.current.forecast : []

                                Rectangle {
                                    id: dayCard
                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    implicitHeight: dayCol.implicitHeight + Style.spaceLg * 2
                                    radius: Style.radiusMd
                                    color: dayHover.containsMouse ? Style.bgTertiary
                                         : index === 0 ? Style.bgTertiary : "transparent"
                                    border.width: index === 0 || dayHover.containsMouse ? 1 : 0
                                    border.color: Style.pinkBorder

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }

                                    ColumnLayout {
                                        id: dayCol
                                        anchors.centerIn: parent
                                        spacing: Style.spaceSm

                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: {
                                                if (dayCard.index === 0) return "Today"
                                                var d = new Date(dayCard.modelData.date + "T00:00:00")
                                                return ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][d.getDay()]
                                            }
                                            font.pixelSize: 11
                                            font.bold: dayCard.index === 0
                                            color: dayCard.index === 0 ? Style.accentPink : Style.textSecondary
                                        }

                                        MaterialIcon {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: dayCard.modelData.icon
                                            font.pixelSize: 20
                                            color: dayCard.index === 0 ? Style.accentPink : Style.textSecondary
                                            fill: 1
                                        }

                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: dayCard.modelData.high + "°"
                                            font.pixelSize: Style.fontSizeSm
                                            font.bold: true
                                            color: Style.textPrimary
                                        }

                                        StyledText {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: dayCard.modelData.low + "°"
                                            font.pixelSize: 11
                                            color: Style.textDimmed
                                        }
                                    }

                                    MouseArea {
                                        id: dayHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onContainsMouseChanged: {
                                            if (containsMouse)
                                                cardContent.hoveredForecastDesc = dayCard.modelData.description
                                            else
                                                cardContent.hoveredForecastDesc = ""
                                        }
                                    }
                                }
                            }
                        }

                        // Forecast hover description
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: cardContent.hoveredForecastDesc
                            font.pixelSize: 11
                            color: Style.textSecondary
                            visible: cardContent.hoveredForecastDesc !== ""
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Style.animFast } }
                        }
                    }

                    // --- Last updated ---
                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        opacity: cardContent.contentOpacity
                        text: {
                            if (!WeatherState.current) return ""
                            var loc = WeatherState.locations[WeatherState.activeLocation]
                            var name = loc ? loc.name : ""
                            var time = WeatherState.current.fetchedAt || ""
                            return name + (time ? "  ·  " + time : "")
                        }
                        font.pixelSize: 11
                        color: Style.textDimmed
                        visible: WeatherState.current !== null
                    }
                }
            }
        }
    }

    // ── Weather Tooltip ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: tipContent.opacity > 0
                && WeatherState.tooltipScreen === modelData
            color: "transparent"
            focusable: false

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 60
            margins.top: Style.barHeight

            exclusionMode: ExclusionMode.Ignore

            Item {
                id: tipContent
                x: WeatherState.tooltipX - width / 2
                y: Style.spaceSm
                width: Math.max(160, tipRow.implicitWidth + Style.spaceXl * 2)
                height: tipRow.implicitHeight + Style.spaceLg * 2

                opacity: WeatherState.tooltipVisible ? 1 : 0
                scale: WeatherState.tooltipVisible ? 1.0 : 0.92

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                // Arrow pointer
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: -4
                    width: 10; height: 10
                    rotation: 45
                    color: Style.bgSecondary
                    border.width: 1
                    border.color: Style.accentPink
                    z: 1
                }

                // Cover arrow bottom border
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: 14; height: 4
                    color: Style.bgSecondary
                    z: 2
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Style.radiusMd
                    color: Style.bgSecondary

                    NeonStrip {}

                    border.width: 1
                    border.color: Style.pinkBorder

                    RowLayout {
                        id: tipRow
                        anchors.centerIn: parent
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: WeatherState.current ? WeatherState.current.icon : "cloud"
                            font.pixelSize: 18
                            color: Style.accentPink
                            fill: 1
                        }

                        StyledText {
                            text: {
                                if (!WeatherState.current) return ""
                                var c = WeatherState.current
                                return c.description + ", " + c.temp + "°C"
                            }
                            font.pixelSize: Style.fontSizeSm
                            color: Style.textPrimary
                        }
                    }
                }
            }
        }
    }
}
