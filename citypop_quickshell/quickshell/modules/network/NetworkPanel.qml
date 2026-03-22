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
            visible: NetworkManager.panelVisible && NetworkManager.panelScreen === modelData
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
                onClicked: NetworkManager.panelVisible = false
            }

            // --- Dropdown Card ---
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Style.barHeight + Style.spaceMd
                anchors.rightMargin: Style.spaceMd
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
                            text: NetworkManager.iconName
                            font.pixelSize: 20
                            color: Style.accentPink
                            fill: 1
                        }

                        StyledText {
                            text: "Wi-Fi"
                            font.pixelSize: Style.fontSizeXl
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        // Scan button
                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Style.radiusFull
                            color: refreshHover.containsMouse ? Style.bgTertiary : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            MaterialIcon {
                                id: refreshIcon
                                anchors.centerIn: parent
                                text: "refresh"
                                font.pixelSize: 16
                                color: refreshHover.containsMouse ? Style.textPrimary : Style.textDimmed

                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                RotationAnimation on rotation {
                                    running: NetworkManager.scanning
                                    from: 0; to: 360
                                    duration: 800
                                    loops: Animation.Infinite
                                }
                            }

                            MouseArea {
                                id: refreshHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NetworkManager.scan()
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
                                onClicked: NetworkManager.panelVisible = false
                            }
                        }
                    }

                    // ── Connected Card ──
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: connectedCol.implicitHeight + Style.spaceLg * 2
                        radius: Style.radiusMd
                        visible: NetworkManager.connected

                        // Subtle pink-tinted background
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
                                    text: "wifi"
                                    font.pixelSize: 20
                                    color: Style.accentPink
                                    fill: 1
                                }

                                ColumnLayout {
                                    spacing: 1
                                    Layout.fillWidth: true

                                    StyledText {
                                        text: NetworkManager.connectionName
                                        font.bold: true
                                        font.pixelSize: Style.fontSizeMd
                                    }

                                    StyledText {
                                        text: "Connected"
                                        color: Style.accentPink
                                        font.pixelSize: Style.fontSizeSm
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
                                        onClicked: NetworkManager.disconnect()
                                    }
                                }
                            }
                        }
                    }

                    // ── Section label ──
                    RowLayout {
                        spacing: Style.spaceSm

                        StyledText {
                            text: "Available Networks"
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
                        visible: NetworkManager.connectError !== ""

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
                                text: NetworkManager.connectError
                                color: Style.colorUrgent
                                font.pixelSize: Style.fontSizeSm
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // ── Network List ──
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: Math.min(contentHeight, 320)
                        clip: true
                        spacing: Style.spaceXs
                        model: NetworkManager.networks

                        delegate: Rectangle {
                            id: netItem
                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            implicitHeight: netCol.implicitHeight + Style.spaceMd * 2
                            radius: Style.radiusSm
                            color: netHover.containsMouse ? Style.bgTertiary : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            readonly property bool isConnected: netItem.modelData.inUse
                            readonly property bool isKnown: NetworkManager.knownConnections.some(
                                n => n === netItem.modelData.ssid
                            )
                            readonly property bool isConnecting: NetworkManager.connectingTo === netItem.modelData.ssid
                            readonly property bool isSecured: netItem.modelData.security !== "" && netItem.modelData.security !== "--"
                            property bool showPassword: false

                            ColumnLayout {
                                id: netCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Style.spaceMd
                                spacing: Style.spaceSm

                                RowLayout {
                                    spacing: Style.spaceMd

                                    // Signal strength bars
                                    Row {
                                        spacing: 2
                                        Layout.alignment: Qt.AlignVCenter

                                        Repeater {
                                            model: 4
                                            Rectangle {
                                                required property int index
                                                readonly property int barLevel: {
                                                    var sig = netItem.modelData.signal
                                                    if (sig >= 80) return 4
                                                    if (sig >= 60) return 3
                                                    if (sig >= 40) return 2
                                                    return 1
                                                }
                                                readonly property bool active: index < barLevel

                                                width: 3
                                                height: 4 + index * 3
                                                radius: 1
                                                anchors.bottom: parent.bottom
                                                color: active
                                                    ? (netItem.isConnected ? Style.accentPink : Style.textSecondary)
                                                    : Style.bgTertiary

                                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                                            }
                                        }
                                    }

                                    StyledText {
                                        text: netItem.modelData.ssid
                                        font.bold: netItem.isConnected
                                        color: netItem.isConnected ? Style.accentPink : Style.textPrimary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Known network badge
                                    MaterialIcon {
                                        text: "bookmark"
                                        font.pixelSize: 14
                                        color: Style.accentAmber
                                        visible: netItem.isKnown && !netItem.isConnected
                                        fill: 1
                                    }

                                    // Lock icon
                                    MaterialIcon {
                                        text: "lock"
                                        font.pixelSize: 13
                                        color: Style.textDimmed
                                        visible: netItem.isSecured
                                    }

                                    // Connecting indicator
                                    MaterialIcon {
                                        text: "sync"
                                        font.pixelSize: 16
                                        color: Style.accentAmber
                                        visible: netItem.isConnecting

                                        RotationAnimation on rotation {
                                            running: netItem.isConnecting
                                            from: 0; to: 360
                                            duration: 800
                                            loops: Animation.Infinite
                                        }
                                    }
                                }

                                // ── Password Row ──
                                RowLayout {
                                    visible: netItem.showPassword
                                    spacing: Style.spaceSm
                                    Layout.topMargin: Style.spaceXs

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 32
                                        radius: Style.radiusSm
                                        color: Style.bgPrimary
                                        border.width: 1
                                        border.color: pwInput.activeFocus ? Style.accentPink : Style.bgTertiary

                                        Behavior on border.color { ColorAnimation { duration: Style.animFast } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Style.spaceMd
                                            anchors.rightMargin: Style.spaceSm
                                            spacing: Style.spaceSm

                                            TextInput {
                                                id: pwInput
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                verticalAlignment: TextInput.AlignVCenter
                                                color: Style.textPrimary
                                                font.family: Style.fontFamily
                                                font.pixelSize: Style.fontSizeSm
                                                echoMode: showPwToggle.checked ? TextInput.Normal : TextInput.Password
                                                clip: true

                                                onAccepted: {
                                                    if (text.length > 0) {
                                                        NetworkManager.connectToNetwork(netItem.modelData.ssid, text)
                                                        netItem.showPassword = false
                                                        text = ""
                                                    }
                                                }
                                            }

                                            // Placeholder
                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.leftMargin: Style.spaceMd
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Enter password..."
                                                color: Style.textDimmed
                                                font.pixelSize: Style.fontSizeSm
                                                visible: !pwInput.activeFocus && pwInput.text === ""
                                            }

                                            // Show/hide password
                                            MaterialIcon {
                                                id: showPwToggle
                                                property bool checked: false
                                                text: checked ? "visibility" : "visibility_off"
                                                font.pixelSize: 16
                                                color: showPwArea.containsMouse ? Style.textPrimary : Style.textDimmed

                                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                                MouseArea {
                                                    id: showPwArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: showPwToggle.checked = !showPwToggle.checked
                                                }
                                            }
                                        }
                                    }

                                    // Connect button
                                    Rectangle {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        radius: Style.radiusSm
                                        color: connBtnHover.containsMouse ? Style.accentMagenta : Style.accentPink

                                        Behavior on color { ColorAnimation { duration: Style.animFast } }

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            text: "arrow_forward"
                                            font.pixelSize: 18
                                            color: Style.bgPrimary
                                        }

                                        MouseArea {
                                            id: connBtnHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (pwInput.text.length > 0) {
                                                    NetworkManager.connectToNetwork(netItem.modelData.ssid, pwInput.text)
                                                    netItem.showPassword = false
                                                    pwInput.text = ""
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: netHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !netItem.showPassword || mouseY < netCol.children[0].height + Style.spaceMd * 2
                                onClicked: {
                                    if (netItem.isConnected) return
                                    if (netItem.isKnown) {
                                        NetworkManager.connectToNetwork(netItem.modelData.ssid, "")
                                    } else {
                                        netItem.showPassword = !netItem.showPassword
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
