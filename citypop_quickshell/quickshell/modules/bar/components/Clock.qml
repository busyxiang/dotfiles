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
    readonly property string h1: rawTime.charAt(0)
    readonly property string h2: rawTime.charAt(1)
    readonly property string m1: rawTime.charAt(3)
    readonly property string m2: rawTime.charAt(4)
    readonly property string s1: rawTime.charAt(6)
    readonly property string s2: rawTime.charAt(7)
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

    readonly property real digitW: Math.round(14 * root.sf)
    readonly property real digitH: Math.round(22 * root.sf)
    readonly property real fontSize: Math.round(Style.fontSizeMd * root.sf)
    readonly property int flipDur: 180

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
        FlipDigit {
            value: root.h1; width: root.digitW; height: root.digitH
            textSize: root.fontSize; animDuration: root.flipDur
        }
        FlipDigit {
            value: root.h2; width: root.digitW; height: root.digitH
            textSize: root.fontSize; animDuration: root.flipDur
            Layout.rightMargin: Math.round(2 * root.sf)
        }

        // Colon 1 (pulsing)
        StyledText {
            text: ":"
            font.bold: true
            font.pixelSize: root.fontSize
            color: Style.accentPink
            opacity: root.colonOpacity
        }

        // Minutes
        FlipDigit {
            value: root.m1; width: root.digitW; height: root.digitH
            textSize: root.fontSize; animDuration: root.flipDur
            Layout.leftMargin: Math.round(2 * root.sf)
        }
        FlipDigit {
            value: root.m2; width: root.digitW; height: root.digitH
            textSize: root.fontSize; animDuration: root.flipDur
            Layout.rightMargin: Math.round(2 * root.sf)
        }

        // Colon 2 (pulsing)
        StyledText {
            text: ":"
            font.bold: true
            font.pixelSize: root.fontSize
            color: Style.accentPink
            opacity: root.colonOpacity
        }

        // Seconds
        FlipDigit {
            value: root.s1; width: root.digitW; height: root.digitH
            textSize: root.fontSize; animDuration: root.flipDur
            Layout.leftMargin: Math.round(2 * root.sf)
        }
        FlipDigit {
            value: root.s2; width: root.digitW; height: root.digitH
            textSize: root.fontSize; animDuration: root.flipDur
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
            CalendarState.panelX = root.mapToItem(null, root.width / 2, 0).x
            var wasOpen = CalendarState.visible
            PanelManager.closeAll()
            if (!wasOpen) {
                CalendarState.screen = root.screen
                CalendarState.visible = true
            }
        }
    }
}
