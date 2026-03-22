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
            visible: CalendarState.visible && CalendarState.screen === modelData
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore

            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: Style.barHeight
                onClicked: CalendarState.visible = false
            }

            // --- Dropdown Card ---
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Style.barHeight + Style.spaceMd
                anchors.rightMargin: Style.spaceMd + 56 // offset to align near clock
                width: 300
                height: cardContent.implicitHeight + Style.spaceXl * 2
                color: Style.bgSecondary
                radius: Style.radiusLg
                border.width: 1
                border.color: Style.bgTertiary

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: Style.spaceXl
                    spacing: Style.spaceLg

                    // ── Current Time ──
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

                    // ── Divider ──
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Style.bgTertiary
                    }

                    // ── Month/Year Header ──
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
                                    var d = new Date(calGrid.viewYear, calGrid.viewMonth - 1, 1)
                                    calGrid.viewYear = d.getFullYear()
                                    calGrid.viewMonth = d.getMonth()
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: {
                                var names = ["January","February","March","April","May","June",
                                             "July","August","September","October","November","December"]
                                return names[calGrid.viewMonth] + " " + calGrid.viewYear
                            }
                            font.pixelSize: Style.fontSizeMd
                            font.bold: true

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var now = new Date()
                                    calGrid.viewYear = now.getFullYear()
                                    calGrid.viewMonth = now.getMonth()
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
                                    var d = new Date(calGrid.viewYear, calGrid.viewMonth + 1, 1)
                                    calGrid.viewYear = d.getFullYear()
                                    calGrid.viewMonth = d.getMonth()
                                }
                            }
                        }
                    }

                    // ── Day-of-week headers ──
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

                    // ── Calendar Grid ──
                    GridLayout {
                        id: calGrid
                        columns: 7
                        columnSpacing: 0
                        rowSpacing: 2
                        Layout.fillWidth: true

                        property int viewYear: new Date().getFullYear()
                        property int viewMonth: new Date().getMonth()

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

                        Repeater {
                            model: calGrid.days

                            Rectangle {
                                id: dayCell
                                required property var modelData
                                required property int index

                                readonly property bool isToday: {
                                    var now = new Date()
                                    return modelData.current &&
                                           modelData.day === now.getDate() &&
                                           calGrid.viewMonth === now.getMonth() &&
                                           calGrid.viewYear === now.getFullYear()
                                }

                                Layout.fillWidth: true
                                implicitHeight: 30
                                radius: Style.radiusFull
                                color: isToday ? Style.accentPink
                                     : dayHover.containsMouse && modelData.current ? Style.bgTertiary
                                     : "transparent"

                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                StyledText {
                                    anchors.centerIn: parent
                                    text: dayCell.modelData.day
                                    font.pixelSize: Style.fontSizeSm
                                    font.bold: dayCell.isToday
                                    color: dayCell.isToday ? Style.bgPrimary
                                         : dayCell.modelData.current ? Style.textPrimary
                                         : Style.textDimmed
                                }

                                MouseArea {
                                    id: dayHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
