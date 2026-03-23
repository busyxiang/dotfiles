pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../Singleton"
import "../../../common"
import "../../calendar"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    // Split time into parts for pulsing colons
    // timeSeconds format: "hh:mm:ss AP"
    readonly property string rawTime: Time.timeSeconds
    readonly property string hourMin: rawTime.substring(0, 5)
    readonly property string seconds: rawTime.substring(6, 8)
    readonly property string ampm: rawTime.substring(9)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // Colon pulse animation
    property real colonOpacity: 1.0
    SequentialAnimation {
        running: true
        loops: Animation.Infinite
        NumberAnimation {
            target: root; property: "colonOpacity"
            from: 1.0; to: 0.3; duration: 500
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root; property: "colonOpacity"
            from: 0.3; to: 1.0; duration: 500
            easing.type: Easing.InOutSine
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 0

        MaterialIcon {
            text: "schedule"
            font.pixelSize: Math.round(16 * root.sf)
            color: Style.accentPink
            fill: 0
            Layout.rightMargin: Math.round(Style.spaceMd * root.sf)
        }

        // Hours
        StyledText {
            text: root.rawTime.substring(0, 2)
            font.bold: true
            font.pixelSize: Math.round(Style.fontSizeMd * root.sf)
            color: Style.accentPink
        }

        // Colon 1 (pulsing)
        StyledText {
            text: ":"
            font.bold: true
            font.pixelSize: Math.round(Style.fontSizeMd * root.sf)
            color: Style.accentPink
            opacity: root.colonOpacity
        }

        // Minutes
        StyledText {
            text: root.rawTime.substring(3, 5)
            font.bold: true
            font.pixelSize: Math.round(Style.fontSizeMd * root.sf)
            color: Style.accentPink
        }

        // Colon 2 (pulsing)
        StyledText {
            text: ":"
            font.bold: true
            font.pixelSize: Math.round(Style.fontSizeMd * root.sf)
            color: Style.accentPink
            opacity: root.colonOpacity
        }

        // Seconds
        StyledText {
            text: root.seconds
            font.bold: true
            font.pixelSize: Math.round(Style.fontSizeMd * root.sf)
            color: Style.accentPink
        }

        // AM/PM
        StyledText {
            text: " " + root.ampm
            font.pixelSize: Math.round(10 * root.sf)
            color: Style.accentPink
            opacity: 0.9
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: Math.round(1 * root.sf)
        }

        // Vertical separator
        Rectangle {
            Layout.leftMargin: Math.round(Style.spaceMd * root.sf)
            Layout.rightMargin: Math.round(Style.spaceMd * root.sf)
            width: 1
            height: Math.round(14 * root.sf)
            color: Style.accentPink
            opacity: 0.4
            Layout.alignment: Qt.AlignVCenter
        }

        // Date
        StyledText {
            text: Time.date
            color: Style.textSecondary
            font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var wasOpen = CalendarState.visible
            PanelManager.closeAll()
            if (!wasOpen) {
                CalendarState.screen = root.screen
                CalendarState.visible = true
            }
        }
    }
}
