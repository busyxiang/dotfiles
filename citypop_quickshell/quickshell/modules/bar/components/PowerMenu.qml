import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../Singleton"
import "../../../common"

Item {
    id: root
    property real sf: 1.0

    implicitWidth: powerIcon.implicitWidth
    implicitHeight: powerIcon.implicitHeight
    property bool menuOpen: false

    MaterialIcon {
        id: powerIcon
        text: "power_settings_new"
        font.pixelSize: Math.round(18 * root.sf)
        color: root.menuOpen ? Style.accentMagenta : Style.textSecondary
        fill: root.menuOpen ? 1 : 0

        Behavior on color {
            ColorAnimation { duration: Style.animFast }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.menuOpen = !root.menuOpen
        }
    }

    Rectangle {
        visible: root.menuOpen
        anchors.top: powerIcon.bottom
        anchors.right: powerIcon.right
        anchors.topMargin: Math.round(Style.spaceMd * root.sf)
        width: Math.round(160 * root.sf)
        color: Style.bgSecondary
        radius: Style.radiusMd
        border.color: Style.bgTertiary
        border.width: 1
        implicitHeight: menuColumn.implicitHeight + Math.round(Style.spaceMd * root.sf) * 2

        Column {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: Math.round(Style.spaceMd * root.sf)
            spacing: Math.round(Style.spaceXs * root.sf)

            Repeater {
                model: [
                    { icon: "lock", label: "Lock", cmd: "hyprlock" },
                    { icon: "logout", label: "Logout", cmd: "hyprctl dispatch exit" },
                    { icon: "restart_alt", label: "Reboot", cmd: "systemctl reboot" },
                    { icon: "power_settings_new", label: "Shutdown", cmd: "systemctl poweroff" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: menuColumn.width - Math.round(Style.spaceMd * root.sf) * 2
                    height: Math.round(32 * root.sf)
                    radius: Style.radiusSm
                    color: hoverArea.containsMouse ? Style.bgTertiary : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Style.animFast }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(Style.spaceSm * root.sf)
                        spacing: Math.round(Style.spaceMd * root.sf)

                        MaterialIcon {
                            text: modelData.icon
                            font.pixelSize: Math.round(16 * root.sf)
                            color: Style.accentPink
                        }

                        StyledText {
                            text: modelData.label
                            font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            proc.command = ["sh", "-c", modelData.cmd]
                            proc.startDetached()
                            root.menuOpen = false
                        }
                    }
                }
            }
        }
    }

    Process { id: proc }
}
