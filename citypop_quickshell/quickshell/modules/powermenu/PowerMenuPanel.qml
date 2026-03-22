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
            visible: PowerMenuState.visible && PowerMenuState.screen === modelData
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore

            // Click outside to close
            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: Style.barHeight
                onClicked: PowerMenuState.visible = false
            }

            // Dropdown card
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Style.barHeight + Style.spaceMd
                anchors.rightMargin: Style.spaceMd
                width: 180
                implicitHeight: menuCol.implicitHeight + Style.spaceLg * 2
                color: Style.bgSecondary
                radius: Style.radiusLg
                border.width: 1
                border.color: Style.bgTertiary

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: menuCol
                    anchors.fill: parent
                    anchors.margins: Style.spaceLg
                    spacing: Style.spaceSm

                    Repeater {
                        model: [
                            { icon: "lock", label: "Lock", cmd: "hyprlock", accent: false },
                            { icon: "logout", label: "Logout", cmd: "hyprctl dispatch exit", accent: false },
                            { icon: "restart_alt", label: "Reboot", cmd: "systemctl reboot", accent: true },
                            { icon: "power_settings_new", label: "Shutdown", cmd: "systemctl poweroff", accent: true }
                        ]

                        delegate: Rectangle {
                            id: menuItem
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            height: 36
                            radius: Style.radiusSm
                            color: itemHover.containsMouse
                                ? (menuItem.modelData.accent ? Qt.rgba(1, 0.27, 0.4, 0.15) : Style.bgTertiary)
                                : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Style.spaceMd
                                anchors.rightMargin: Style.spaceMd
                                spacing: Style.spaceMd

                                MaterialIcon {
                                    text: menuItem.modelData.icon
                                    font.pixelSize: 18
                                    color: itemHover.containsMouse
                                        ? (menuItem.modelData.accent ? Style.colorUrgent : Style.accentPink)
                                        : Style.textSecondary

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                }

                                StyledText {
                                    text: menuItem.modelData.label
                                    font.pixelSize: Style.fontSizeMd
                                    color: itemHover.containsMouse
                                        ? (menuItem.modelData.accent ? Style.colorUrgent : Style.textPrimary)
                                        : Style.textSecondary
                                    Layout.fillWidth: true

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                }
                            }

                            MouseArea {
                                id: itemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    proc.command = ["sh", "-c", menuItem.modelData.cmd]
                                    proc.startDetached()
                                    PowerMenuState.visible = false
                                }
                            }
                        }
                    }
                }
            }

            Process { id: proc }
        }
    }
}
