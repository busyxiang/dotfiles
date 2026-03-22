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
            visible: BluetoothManager.panelVisible && BluetoothManager.panelScreen === modelData
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
                onClicked: BluetoothManager.panelVisible = false
            }

            // --- Dropdown Card ---
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Style.barHeight + Style.spaceMd
                anchors.rightMargin: Style.spaceMd + 250
                width: 360
                height: Math.min(cardContent.implicitHeight + Style.spaceXl * 2, 520)
                color: Style.bgSecondary
                radius: Style.radiusLg
                border.width: 1
                border.color: Style.bgTertiary

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
                                GradientStop { position: 0.0; color: Qt.rgba(1, 0.41, 0.71, 0.12) }
                                GradientStop { position: 1.0; color: Qt.rgba(1, 0.41, 0.71, 0.04) }
                            }
                            border.width: 1
                            border.color: Qt.rgba(1, 0.41, 0.71, 0.3)

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
                                        color: dcHover.containsMouse ? Qt.rgba(1, 0.27, 0.4, 0.15) : "transparent"
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
                            color: Style.bgTertiary
                        }
                    }

                    // ── Error ──
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: errorRow.implicitHeight + Style.spaceMd * 2
                        radius: Style.radiusSm
                        color: Qt.rgba(1, 0.27, 0.4, 0.1)
                        border.width: 1
                        border.color: Qt.rgba(1, 0.27, 0.4, 0.3)
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
                        color: Qt.rgba(1, 0.7, 0.28, 0.1)
                        border.width: 1
                        border.color: Qt.rgba(1, 0.7, 0.28, 0.3)
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
                            color: devHover.containsMouse ? Style.bgTertiary : "transparent"

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
                                    color: forgetHover.containsMouse ? Qt.rgba(1, 0.27, 0.4, 0.15) : "transparent"

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
                                    color: connHover.containsMouse ? Qt.rgba(1, 0.41, 0.71, 0.15) : "transparent"
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
}
