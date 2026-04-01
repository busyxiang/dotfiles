pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Singleton"
import "../../common"
import "../lock"

Scope {
    // Countdown state (lifted from PanelWindow)
    property string pendingCmd: ""
    property int countdown: 0

    function startCountdown(cmd: string): void {
        pendingCmd = cmd
        countdown = 5
        countdownTimer.start()
    }

    function cancelCountdown(): void {
        countdownTimer.stop()
        pendingCmd = ""
        countdown = 0
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            countdown--
            if (countdown <= 0 && pendingCmd !== "") {
                countdownTimer.stop()
                proc.command = ["sh", "-c", pendingCmd]
                proc.startDetached()
                cancelCountdown()
                PowerMenuState.visible = false
            }
        }
    }

    Process { id: proc }

    Variants {
        model: Quickshell.screens

        DropdownPanel {
            id: panel
            required property var modelData
            screen: modelData

            stateOpen: PowerMenuState.visible
            stateScreen: PowerMenuState.screen
            onDismissed: PowerMenuState.visible = false

            cardWidth: 200
            cardPadding: Style.spaceLg
            anchorMode: "widget"
            widgetCenterX: PowerMenuState.panelX

            // Reset countdown when panel closes
            onVisibleChanged: {
                if (!visible) cancelCountdown()
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: Style.spaceSm

                Repeater {
                    model: [
                        { icon: "lock", label: "Lock", cmd: "__lock__", accent: false },
                        { icon: "logout", label: "Logout", cmd: "hyprctl dispatch exit", accent: false },
                        { icon: "restart_alt", label: "Reboot", cmd: "systemctl reboot", accent: true },
                        { icon: "power_settings_new", label: "Shutdown", cmd: "systemctl poweroff", accent: true }
                    ]

                    delegate: Rectangle {
                        id: menuItem
                        required property var modelData
                        required property int index

                        readonly property bool isPending: pendingCmd === menuItem.modelData.cmd && countdown > 0

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
                            width: menuItem.isPending ? parent.width * (countdown / 5) : 0
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
                                    ? "Cancel (" + countdown + "s)"
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
                                    cancelCountdown()
                                } else if (menuItem.modelData.accent) {
                                    startCountdown(menuItem.modelData.cmd)
                                } else if (menuItem.modelData.cmd === "__lock__") {
                                    PowerMenuState.visible = false
                                    LockState.screen = panel.modelData
                                    LockState.lock()
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
    }
}
