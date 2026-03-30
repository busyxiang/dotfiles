pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
            property bool _open: CalendarState.visible && CalendarState.screen === modelData
            visible: CalendarState.visible || card.opacity > 0
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
                onClicked: CalendarState.visible = false
            }

            // --- Dropdown Card ---
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Math.round(Style.spaceMd * panel.sf)
                anchors.rightMargin: Math.round((Style.spaceMd + 56) * panel.sf) // offset to align near clock
                width: 320
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

                // Close button (floating top-right)
                CloseButton {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: Style.spaceMd
                    anchors.rightMargin: Style.spaceMd
                    z: 2
                    onClicked: CalendarState.visible = false
                }

                // --- Clipboard Process ---
                Process {
                    id: clipProc
                    command: ["wl-copy", ""]
                }

                // --- Copied feedback state ---
                property string copiedText: ""
                property bool showCopied: false

                Timer {
                    id: copiedTimer
                    interval: 1200
                    onTriggered: card.showCopied = false
                }

                function copyDate(day: int): void {
                    var monthNames = ["January","February","March","April","May","June",
                                      "July","August","September","October","November","December"]
                    var dateStr = monthNames[calendarArea.viewMonth] + " " + day + ", " + calendarArea.viewYear
                    clipProc.command = ["wl-copy", dateStr]
                    clipProc.startDetached()
                    copiedText = dateStr
                    showCopied = true
                    copiedTimer.restart()
                }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: Style.spaceXl
                    spacing: Style.spaceLg

                    // -- Current Time --
                    ColumnLayout {
                        spacing: Style.spaceXs

                        StyledText {
                            text: Time.timeSeconds
                            font.pixelSize: 32
                            font.bold: true
                            color: Style.accentPink
                        }

                        StyledText {
                            text: Qt.formatDateTime(new Date(), "dddd, MMMM d, yyyy")
                            color: Style.textSecondary
                            font.pixelSize: Style.fontSizeSm
                        }
                    }

                    // -- Neon Divider --
                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Style.accentPink
                        opacity: 0.6
                    }

                    // -- Month/Year Header --
                    RowLayout {
                        spacing: Style.spaceMd

                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Style.radiusFull
                            color: prevHover.containsMouse ? Style.bgTertiary : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "chevron_left"
                                font.pixelSize: 18
                                color: prevHover.containsMouse ? Style.textPrimary : Style.textDimmed
                            }

                            MouseArea {
                                id: prevHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    calendarArea.direction = -1
                                    calendarArea.animateTransition()
                                    var d = new Date(calendarArea.viewYear, calendarArea.viewMonth - 1, 1)
                                    calendarArea.viewYear = d.getFullYear()
                                    calendarArea.viewMonth = d.getMonth()
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: {
                                var names = ["January","February","March","April","May","June",
                                             "July","August","September","October","November","December"]
                                return names[calendarArea.viewMonth] + " " + calendarArea.viewYear
                            }
                            font.pixelSize: Style.fontSizeMd
                            font.bold: true

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var now = new Date()
                                    calendarArea.viewYear = now.getFullYear()
                                    calendarArea.viewMonth = now.getMonth()
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Style.radiusFull
                            color: nextHover.containsMouse ? Style.bgTertiary : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "chevron_right"
                                font.pixelSize: 18
                                color: nextHover.containsMouse ? Style.textPrimary : Style.textDimmed
                            }

                            MouseArea {
                                id: nextHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    calendarArea.direction = 1
                                    calendarArea.animateTransition()
                                    var d = new Date(calendarArea.viewYear, calendarArea.viewMonth + 1, 1)
                                    calendarArea.viewYear = d.getFullYear()
                                    calendarArea.viewMonth = d.getMonth()
                                }
                            }
                        }
                    }

                    // -- Day-of-week headers (with week number spacer) --
                    RowLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        // Week number column header
                        Item {
                            implicitWidth: 26
                            implicitHeight: 20

                            StyledText {
                                anchors.centerIn: parent
                                text: "W"
                                color: Style.textDimmed
                                font.pixelSize: 11
                            }
                        }

                        // Thin separator
                        Rectangle {
                            implicitWidth: 1
                            implicitHeight: 16
                            Layout.alignment: Qt.AlignVCenter
                            color: Style.bgTertiary
                        }

                        GridLayout {
                            columns: 7
                            columnSpacing: 0
                            rowSpacing: 0
                            Layout.fillWidth: true

                            Repeater {
                                model: ["Su","Mo","Tu","We","Th","Fr","Sa"]

                                StyledText {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    text: modelData
                                    color: Style.textDimmed
                                    font.pixelSize: Style.fontSizeSm
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }

                    // -- Calendar Grid with transition animation --
                    Item {
                        id: calendarArea
                        Layout.fillWidth: true
                        implicitHeight: calGrid.implicitHeight
                        clip: true

                        property int viewYear: new Date().getFullYear()
                        property int viewMonth: new Date().getMonth()
                        property int direction: 1 // 1 = forward, -1 = back

                        // Transition animation properties
                        property real gridOpacity: 1.0
                        property real gridTranslateX: 0

                        function animateTransition(): void {
                            // Start: slide out in the given direction
                            gridOpacity = 0.0
                            gridTranslateX = -direction * 30
                            // After a brief moment, snap to the incoming side and animate in
                            snapInTimer.start()
                        }

                        Timer {
                            id: snapInTimer
                            interval: 80
                            onTriggered: {
                                // Snap to opposite side
                                calendarArea.gridTranslateX = calendarArea.direction * 30
                                // Now animate back to center
                                slideInAnim.start()
                                fadeInAnim.start()
                            }
                        }

                        NumberAnimation {
                            id: slideInAnim
                            target: calendarArea
                            property: "gridTranslateX"
                            to: 0
                            duration: Style.animNormal
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            id: fadeInAnim
                            target: calendarArea
                            property: "gridOpacity"
                            to: 1.0
                            duration: Style.animNormal
                            easing.type: Easing.OutCubic
                        }

                        property var days: {
                            var result = []
                            var firstDay = new Date(viewYear, viewMonth, 1)
                            var startDow = firstDay.getDay() // 0=Sun
                            var daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
                            var daysInPrev = new Date(viewYear, viewMonth, 0).getDate()

                            // Previous month padding
                            for (var i = startDow - 1; i >= 0; i--)
                                result.push({ day: daysInPrev - i, current: false })

                            // Current month
                            for (var d = 1; d <= daysInMonth; d++)
                                result.push({ day: d, current: true })

                            // Next month padding
                            while (result.length < 42)
                                result.push({ day: result.length - startDow - daysInMonth + 1, current: false })

                            return result
                        }

                        // Compute ISO week numbers for each row
                        property var weekNumbers: {
                            var weeks = []
                            for (var row = 0; row < 6; row++) {
                                var idx = row * 7
                                var entry = days[idx]
                                // Figure out the actual date for the first cell in this row
                                var actualMonth = viewMonth
                                var actualYear = viewYear
                                if (!entry.current) {
                                    if (row === 0) {
                                        // Previous month
                                        var prev = new Date(viewYear, viewMonth - 1, 1)
                                        actualMonth = prev.getMonth()
                                        actualYear = prev.getFullYear()
                                    } else {
                                        // Next month
                                        var next = new Date(viewYear, viewMonth + 1, 1)
                                        actualMonth = next.getMonth()
                                        actualYear = next.getFullYear()
                                    }
                                }
                                // Use Thursday of that week for ISO week calc
                                // The row starts on Sunday; Thursday is idx+4
                                var thuEntry = days[idx + 4]
                                var thuMonth = viewMonth
                                var thuYear = viewYear
                                if (!thuEntry.current) {
                                    if (row === 0) {
                                        var p = new Date(viewYear, viewMonth - 1, 1)
                                        thuMonth = p.getMonth()
                                        thuYear = p.getFullYear()
                                    } else {
                                        var n = new Date(viewYear, viewMonth + 1, 1)
                                        thuMonth = n.getMonth()
                                        thuYear = n.getFullYear()
                                    }
                                }
                                var thuDate = new Date(thuYear, thuMonth, thuEntry.day)
                                // ISO week number: week containing Jan 4
                                var jan4 = new Date(thuDate.getFullYear(), 0, 4)
                                var startOfYear = new Date(jan4.getTime())
                                startOfYear.setDate(jan4.getDate() - ((jan4.getDay() + 6) % 7))
                                var diff = thuDate.getTime() - startOfYear.getTime()
                                var weekNum = Math.floor(diff / (7 * 24 * 60 * 60 * 1000)) + 1
                                weeks.push(weekNum)
                            }
                            return weeks
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            opacity: calendarArea.gridOpacity
                            transform: Translate { x: calendarArea.gridTranslateX }

                            // -- Week numbers column --
                            ColumnLayout {
                                spacing: Style.spaceXs
                                Layout.alignment: Qt.AlignTop

                                Repeater {
                                    model: calendarArea.weekNumbers

                                    Item {
                                        required property int modelData
                                        implicitWidth: 26
                                        implicitHeight: 30

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: parent.modelData
                                            color: Style.textDimmed
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }

                            // Thin separator
                            Rectangle {
                                implicitWidth: 1
                                Layout.fillHeight: true
                                color: Style.bgTertiary
                                Layout.alignment: Qt.AlignTop
                            }

                            // -- Day grid --
                            GridLayout {
                                id: calGrid
                                columns: 7
                                columnSpacing: 0
                                rowSpacing: 2
                                Layout.fillWidth: true

                                Repeater {
                                    model: calendarArea.days

                                    Rectangle {
                                        id: dayCell
                                        required property var modelData
                                        required property int index

                                        readonly property bool isToday: {
                                            var now = new Date()
                                            return modelData.current &&
                                                   modelData.day === now.getDate() &&
                                                   calendarArea.viewMonth === now.getMonth() &&
                                                   calendarArea.viewYear === now.getFullYear()
                                        }

                                        Layout.fillWidth: true
                                        implicitHeight: 30
                                        radius: Style.radiusFull
                                        color: !isToday && dayHover.containsMouse && modelData.current ? Style.bgTertiary
                                             : "transparent"

                                        Behavior on color { ColorAnimation { duration: Style.animFast } }

                                        // Today highlight circle (fixed size, centered)
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 30
                                            height: 30
                                            radius: Style.radiusFull
                                            color: Style.accentPink
                                            visible: dayCell.isToday

                                            // Neon glow ring
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: parent.width + 6
                                                height: parent.height + 6
                                                radius: Style.radiusFull
                                                color: "transparent"
                                                border.width: 2
                                                border.color: Style.accentPink
                                                opacity: 0.4
                                            }
                                        }

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: dayCell.modelData.day
                                            font.pixelSize: Style.fontSizeSm
                                            font.bold: dayCell.isToday
                                            color: dayCell.isToday ? Style.bgPrimary
                                                 : dayCell.modelData.current ? Style.textPrimary
                                                 : Style.textDimmed
                                        }

                                        // "Copied" flash overlay
                                        Rectangle {
                                            id: flashOverlay
                                            anchors.fill: parent
                                            radius: parent.radius
                                            color: Style.accentPink
                                            opacity: 0

                                            SequentialAnimation {
                                                id: flashAnim
                                                NumberAnimation {
                                                    target: flashOverlay
                                                    property: "opacity"
                                                    to: 0.5
                                                    duration: Style.animFast
                                                }
                                                NumberAnimation {
                                                    target: flashOverlay
                                                    property: "opacity"
                                                    to: 0
                                                    duration: Style.animSlow
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: dayHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: dayCell.modelData.current ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                if (dayCell.modelData.current) {
                                                    card.copyDate(dayCell.modelData.day)
                                                    flashAnim.start()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // -- Copied tooltip --
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: card.showCopied ? 24 : 0
                        color: Style.bgTertiary
                        radius: Style.radiusSm
                        clip: true
                        visible: card.showCopied

                        Behavior on implicitHeight { NumberAnimation { duration: Style.animFast } }

                        StyledText {
                            anchors.centerIn: parent
                            text: "Copied: " + card.copiedText
                            font.pixelSize: 11
                            color: Style.accentPink
                        }
                    }
                }
            }
        }
    }
}
