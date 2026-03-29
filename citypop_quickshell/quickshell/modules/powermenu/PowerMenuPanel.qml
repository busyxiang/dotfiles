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
            property bool _open: PowerMenuState.visible && PowerMenuState.screen === modelData
            visible: PowerMenuState.visible || powerCard.opacity > 0
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore
            margins.top: Math.round(Style.barHeight * panel.sf)

            // Countdown state
            property string pendingCmd: ""
            property int countdown: 0

            function startCountdown(cmd, label) {
                pendingCmd = cmd
                countdown = 5
                countdownTimer.start()
            }

            function cancelCountdown() {
                countdownTimer.stop()
                pendingCmd = ""
                countdown = 0
            }

            Timer {
                id: countdownTimer
                interval: 1000
                repeat: true
                onTriggered: {
                    panel.countdown--
                    if (panel.countdown <= 0 && panel.pendingCmd !== "") {
                        countdownTimer.stop()
                        proc.command = ["sh", "-c", panel.pendingCmd]
                        proc.startDetached()
                        panel.cancelCountdown()
                        PowerMenuState.visible = false
                    }
                }
            }

            // Reset countdown when panel closes
            onVisibleChanged: {
                if (!visible) cancelCountdown()
            }

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked: PowerMenuState.visible = false
            }

            // Dropdown card
            Rectangle {
                id: powerCard
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Math.round(Style.spaceMd * panel.sf)
                anchors.rightMargin: Math.round(Style.spaceMd * panel.sf)
                width: 200
                implicitHeight: menuCol.implicitHeight + Style.spaceLg * 2
                color: Style.bgSecondary
                radius: Style.radiusLg

                opacity: panel._open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: panel._open ? 0 : -8
                    Behavior on y { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                }
                border.width: 1
                border.color: Style.bgTertiary

                NeonStrip {}

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

                            readonly property bool isPending: panel.pendingCmd === menuItem.modelData.cmd && panel.countdown > 0

                            Layout.fillWidth: true
                            height: 36
                            radius: Style.radiusSm
                            color: isPending ? Style.urgentBgStrong
                                 : itemHover.containsMouse
                                    ? (menuItem.modelData.accent ? Style.urgentHover : Style.bgTertiary)
                                    : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            // Countdown progress bar
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: menuItem.isPending ? parent.width * (panel.countdown / 5) : 0
                                radius: parent.radius
                                color: Style.urgentHover
                                visible: menuItem.isPending

                                Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Style.spaceMd
                                anchors.rightMargin: Style.spaceMd
                                spacing: Style.spaceMd

                                MaterialIcon {
                                    text: menuItem.isPending ? "cancel" : menuItem.modelData.icon
                                    font.pixelSize: 18
                                    color: menuItem.isPending ? Style.colorUrgent
                                         : itemHover.containsMouse
                                            ? (menuItem.modelData.accent ? Style.colorUrgent : Style.accentPink)
                                            : Style.textSecondary

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                }

                                StyledText {
                                    text: menuItem.isPending
                                        ? "Cancel (" + panel.countdown + "s)"
                                        : menuItem.modelData.label
                                    font.pixelSize: Style.fontSizeMd
                                    color: menuItem.isPending ? Style.colorUrgent
                                         : itemHover.containsMouse
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
                                    if (menuItem.isPending) {
                                        panel.cancelCountdown()
                                    } else if (menuItem.modelData.accent) {
                                        panel.startCountdown(menuItem.modelData.cmd, menuItem.modelData.label)
                                    } else {
                                        proc.command = ["sh", "-c", menuItem.modelData.cmd]
                                        proc.startDetached()
                                        PowerMenuState.visible = false
                                    }
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
