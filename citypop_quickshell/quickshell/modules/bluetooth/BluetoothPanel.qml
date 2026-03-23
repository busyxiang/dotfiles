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
            property bool _open: BluetoothManager.panelVisible && BluetoothManager.panelScreen === modelData
            visible: BluetoothManager.panelVisible || card.opacity > 0
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
                onClicked: BluetoothManager.panelVisible = false
            }

            // --- Dropdown Card ---
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Math.round(Style.spaceMd * panel.sf)
                anchors.rightMargin: Math.round((Style.spaceMd + 250) * panel.sf)
                width: 360
                height: Math.min(cardContent.implicitHeight + Style.spaceXl * 2, 520)
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

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: Style.spaceXl
                    spacing: Style.spaceMd

                    // ── Header ──
                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: BluetoothManager.powered ? "bluetooth" : "bluetooth_disabled"
                            font.pixelSize: 20
                            color: Style.accentPink
                            fill: 1
                        }

                        StyledText {
                            text: "Bluetooth"
                            font.pixelSize: Style.fontSizeXl
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        // Power toggle
                        Rectangle {
                            implicitWidth: 44
                            implicitHeight: 24
                            radius: Style.radiusFull
                            color: BluetoothManager.powered ? Style.accentPink : Style.bgTertiary

                            Behavior on color { ColorAnimation { duration: Style.animNormal } }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: Style.radiusFull
                                anchors.verticalCenter: parent.verticalCenter
                                x: BluetoothManager.powered ? parent.width - width - 3 : 3
                                color: Style.textPrimary

                                Behavior on x { NumberAnimation { duration: Style.animNormal } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BluetoothManager.togglePower()
                            }
                        }

                        // Scan button
                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Style.radiusFull
                            color: scanHover.containsMouse ? Style.bgTertiary : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            MaterialIcon {
                                id: scanIcon
                                anchors.centerIn: parent
                                text: "refresh"
                                font.pixelSize: 16
                                color: scanHover.containsMouse ? Style.textPrimary : Style.textDimmed

                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                RotationAnimation on rotation {
                                    running: BluetoothManager.scanning
                                    from: 0; to: 360
                                    duration: 800
                                    loops: Animation.Infinite
                                }
                            }

                            MouseArea {
                                id: scanHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BluetoothManager.scan()
                            }
                        }

                        // Close
                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Style.radiusFull
                            color: closeHover.containsMouse ? Style.bgTertiary : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "close"
                                font.pixelSize: 16
                                color: closeHover.containsMouse ? Style.textPrimary : Style.textDimmed
                            }

                            MouseArea {
                                id: closeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BluetoothManager.panelVisible = false
                            }
                        }
                    }

                    // Neon header divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Style.accentPink
                        opacity: 0.6
                    }

                    // ── Connected Devices ──
                    Repeater {
                        model: BluetoothManager.connectedDevices

                        Rectangle {
                            id: connectedItem
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: connectedCol.implicitHeight + Style.spaceLg * 2
                            radius: Style.radiusMd

                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Style.pinkGradientStart }
                                GradientStop { position: 1.0; color: Style.pinkGradientEnd }
                            }
                            border.width: 1
                            border.color: Style.pinkBorder

                            ColumnLayout {
                                id: connectedCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Style.spaceLg
                                spacing: Style.spaceSm

                                RowLayout {
                                    spacing: Style.spaceMd

                                    MaterialIcon {
                                        text: connectedItem.modelData.icon
                                        font.pixelSize: 20
                                        color: Style.accentPink
                                        fill: 1
                                    }

                                    ColumnLayout {
                                        spacing: 1
                                        Layout.fillWidth: true

                                        StyledText {
                                            text: connectedItem.modelData.name
                                            font.bold: true
                                            font.pixelSize: Style.fontSizeMd
                                        }

                                        StyledText {
                                            text: "Connected"
                                            color: Style.accentPink
                                            font.pixelSize: Style.fontSizeSm
                                        }
                                    }

                                    // Battery indicator
                                    RowLayout {
                                        spacing: Style.spaceXs
                                        visible: connectedItem.modelData.battery >= 0

                                        MaterialIcon {
                                            text: {
                                                var b = connectedItem.modelData.battery
                                                if (b > 80) return "battery_full"
                                                if (b > 50) return "battery_5_bar"
                                                if (b > 20) return "battery_3_bar"
                                                return "battery_1_bar"
                                            }
                                            font.pixelSize: 16
                                            color: connectedItem.modelData.battery > 20 ? Style.textSecondary : Style.colorUrgent
                                        }

                                        StyledText {
                                            text: connectedItem.modelData.battery + "%"
                                            font.pixelSize: Style.fontSizeSm
                                            color: connectedItem.modelData.battery > 20 ? Style.textSecondary : Style.colorUrgent
                                        }
                                    }

                                    // Disconnect pill
                                    Rectangle {
                                        implicitWidth: dcRow.implicitWidth + Style.spaceLg * 2
                                        implicitHeight: 28
                                        radius: Style.radiusFull
                                        color: dcHover.containsMouse ? Style.urgentHover : "transparent"
                                        border.width: 1
                                        border.color: dcHover.containsMouse ? Style.colorUrgent : Style.textDimmed

                                        Behavior on color { ColorAnimation { duration: Style.animFast } }
                                        Behavior on border.color { ColorAnimation { duration: Style.animFast } }

                                        RowLayout {
                                            id: dcRow
                                            anchors.centerIn: parent
                                            spacing: Style.spaceSm

                                            MaterialIcon {
                                                text: "link_off"
                                                font.pixelSize: 14
                                                color: dcHover.containsMouse ? Style.colorUrgent : Style.textDimmed

                                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                                            }

                                            StyledText {
                                                text: "Disconnect"
                                                color: dcHover.containsMouse ? Style.colorUrgent : Style.textDimmed
                                                font.pixelSize: Style.fontSizeSm

                                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                                            }
                                        }

                                        MouseArea {
                                            id: dcHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: BluetoothManager.disconnectDevice(connectedItem.modelData.mac)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Section label ──
                    RowLayout {
                        spacing: Style.spaceSm

                        StyledText {
                            text: "Paired Devices"
                            color: Style.textDimmed
                            font.pixelSize: Style.fontSizeSm
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Style.accentPink
                            opacity: 0.3
                        }
                    }

                    // ── Error ──
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: errorRow.implicitHeight + Style.spaceMd * 2
                        radius: Style.radiusSm
                        color: Style.urgentBg
                        border.width: 1
                        border.color: Style.urgentBorder
                        visible: BluetoothManager.connectError !== ""

                        RowLayout {
                            id: errorRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Style.spaceMd
                            spacing: Style.spaceSm

                            MaterialIcon {
                                text: "error"
                                font.pixelSize: 16
                                color: Style.colorUrgent
                            }

                            StyledText {
                                text: BluetoothManager.connectError
                                color: Style.colorUrgent
                                font.pixelSize: Style.fontSizeSm
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // ── Pairing PIN display ──
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: pinRow.implicitHeight + Style.spaceMd * 2
                        radius: Style.radiusSm
                        color: Style.amberBg
                        border.width: 1
                        border.color: Style.amberBorder
                        visible: BluetoothManager.pairingPin !== ""

                        RowLayout {
                            id: pinRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Style.spaceMd
                            spacing: Style.spaceMd

                            MaterialIcon {
                                text: "pin"
                                font.pixelSize: 16
                                color: Style.accentAmber
                            }

                            ColumnLayout {
                                spacing: Style.spaceXs
                                Layout.fillWidth: true

                                StyledText {
                                    text: "Pairing PIN"
                                    color: Style.accentAmber
                                    font.pixelSize: Style.fontSizeSm
                                }

                                StyledText {
                                    text: BluetoothManager.pairingPin
                                    color: Style.textPrimary
                                    font.pixelSize: Style.fontSizeXl
                                    font.bold: true
                                    font.letterSpacing: 4
                                }
                            }
                        }
                    }

                    // ── Scanning indicator ──
                    RowLayout {
                        visible: BluetoothManager.scanning
                        spacing: Style.spaceSm

                        MaterialIcon {
                            text: "bluetooth_searching"
                            font.pixelSize: 16
                            color: Style.accentAmber

                            SequentialAnimation on opacity {
                                running: BluetoothManager.scanning
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
                                NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
                            }
                        }

                        StyledText {
                            text: "Scanning for devices..."
                            color: Style.accentAmber
                            font.pixelSize: Style.fontSizeSm
                        }
                    }

                    // ── Device List ──
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: Math.min(contentHeight, 320)
                        clip: true
                        spacing: Style.spaceXs
                        model: BluetoothManager.devices.filter(d => !d.connected)

                        delegate: Rectangle {
                            id: devItem
                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            implicitHeight: devRow.implicitHeight + Style.spaceMd * 2
                            radius: Style.radiusSm
                            color: devHover.containsMouse ? Style.pinkHover : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            readonly property bool isConnecting: BluetoothManager.connectingTo === devItem.modelData.mac

                            RowLayout {
                                id: devRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Style.spaceMd
                                spacing: Style.spaceMd

                                MaterialIcon {
                                    text: devItem.modelData.icon
                                    font.pixelSize: 18
                                    color: Style.textSecondary
                                    fill: 1
                                }

                                StyledText {
                                    text: devItem.modelData.name
                                    font.pixelSize: Style.fontSizeMd
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Connecting indicator
                                MaterialIcon {
                                    text: "sync"
                                    font.pixelSize: 16
                                    color: Style.accentAmber
                                    visible: devItem.isConnecting

                                    RotationAnimation on rotation {
                                        running: devItem.isConnecting
                                        from: 0; to: 360
                                        duration: 800
                                        loops: Animation.Infinite
                                    }
                                }

                                // Forget / unpair button (visible on hover for paired, non-connecting devices)
                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: Style.radiusFull
                                    visible: devHover.containsMouse && devItem.modelData.paired && !devItem.isConnecting
                                    color: forgetHover.containsMouse ? Style.urgentHover : "transparent"

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "delete"
                                        font.pixelSize: 16
                                        color: forgetHover.containsMouse ? Style.colorUrgent : Style.textDimmed

                                        Behavior on color { ColorAnimation { duration: Style.animFast } }
                                    }

                                    MouseArea {
                                        id: forgetHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: BluetoothManager.removeDevice(devItem.modelData.mac)
                                    }
                                }

                                // Connect pill
                                Rectangle {
                                    implicitWidth: connRow.implicitWidth + Style.spaceLg * 2
                                    implicitHeight: 28
                                    radius: Style.radiusFull
                                    visible: !devItem.isConnecting
                                    color: connHover.containsMouse ? Style.pinkHover : "transparent"
                                    border.width: 1
                                    border.color: connHover.containsMouse ? Style.accentPink : Style.textDimmed

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                    Behavior on border.color { ColorAnimation { duration: Style.animFast } }

                                    RowLayout {
                                        id: connRow
                                        anchors.centerIn: parent
                                        spacing: Style.spaceSm

                                        MaterialIcon {
                                            text: "bluetooth"
                                            font.pixelSize: 14
                                            color: connHover.containsMouse ? Style.accentPink : Style.textDimmed

                                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                                        }

                                        StyledText {
                                            text: "Connect"
                                            color: connHover.containsMouse ? Style.accentPink : Style.textDimmed
                                            font.pixelSize: Style.fontSizeSm

                                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                                        }
                                    }

                                    MouseArea {
                                        id: connHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: BluetoothManager.connectDevice(devItem.modelData.mac)
                                    }
                                }
                            }

                            MouseArea {
                                id: devHover
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Bluetooth Tooltip ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: btTooltipContent.opacity > 0
                && BluetoothManager.tooltipScreen === modelData
            color: "transparent"
            focusable: false

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Style.barHeight + Style.spaceMd + 80

            exclusionMode: ExclusionMode.Ignore

            Item {
                id: btTooltipContent
                x: BluetoothManager.tooltipX - width / 2
                y: Style.barHeight + Style.spaceSm
                width: Math.max(160, btTooltipColumn.implicitWidth + Style.spaceXl * 2)
                height: btTooltipColumn.implicitHeight + Style.spaceLg * 2

                opacity: BluetoothManager.tooltipVisible ? 1 : 0
                scale: BluetoothManager.tooltipVisible ? 1.0 : 0.92

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
                    width: 10
                    height: 10
                    rotation: 45
                    color: Style.bgSecondary
                    border.width: 1
                    border.color: Style.accentPink
                    z: 1
                }

                // Cover the arrow's bottom border where it meets the card
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: 14
                    height: 4
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

                    ColumnLayout {
                        id: btTooltipColumn
                        anchors.centerIn: parent
                        spacing: Style.spaceSm

                        Repeater {
                            model: BluetoothManager.connectedDevices

                            delegate: RowLayout {
                                required property var modelData
                                spacing: Style.spaceSm

                                MaterialIcon {
                                    text: modelData.icon
                                    font.pixelSize: 14
                                    color: Style.accentPink
                                    fill: 1
                                }

                                StyledText {
                                    text: modelData.name
                                    font.pixelSize: Style.fontSizeSm
                                    font.bold: true
                                    color: Style.textPrimary
                                }

                                // Battery if available
                                StyledText {
                                    visible: modelData.battery >= 0
                                    text: modelData.battery + "%"
                                    font.pixelSize: Style.fontSizeSm
                                    color: modelData.battery > 20 ? Style.textSecondary : Style.colorUrgent
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
