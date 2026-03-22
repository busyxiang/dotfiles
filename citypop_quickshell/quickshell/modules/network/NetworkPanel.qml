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
                            spacing: Style.spaceMd

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

                            // ── Signal VU meter ──
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.spaceMd

                                Row {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Repeater {
                                        model: 10

                                        Rectangle {
                                            required property int index
                                            property bool isLit: NetworkManager.signalStrength > index * 10

                                            width: (parent.width - 9 * parent.spacing) / 10
                                            height: 6
                                            radius: 1
                                            color: isLit ? Style.accentPink : Style.bgTertiary

                                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                                        }
                                    }
                                }

                                StyledText {
                                    text: NetworkManager.signalStrength + "%"
                                    font.pixelSize: Style.fontSizeSm
                                    color: Style.textSecondary
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

                            // Pulsing border for connecting state
                            border.width: netItem.isConnecting ? 1 : 0
                            border.color: Style.accentPink

                            SequentialAnimation {
                                running: netItem.isConnecting
                                loops: Animation.Infinite
                                NumberAnimation {
                                    target: netItem; property: "opacity"
                                    from: 1.0; to: 0.7; duration: 600
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    target: netItem; property: "opacity"
                                    from: 0.7; to: 1.0; duration: 600
                                    easing.type: Easing.InOutSine
                                }
                            }

                            ColumnLayout {
                                id: netCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Style.spaceMd
                                spacing: Style.spaceSm

                                RowLayout {
                                    spacing: Style.spaceMd

                                    // Wifi icon with signal-based variant
                                    MaterialIcon {
                                        text: {
                                            var sig = netItem.modelData.signal
                                            if (sig >= 60) return "wifi"
                                            if (sig >= 30) return "wifi_2_bar"
                                            return "wifi_1_bar"
                                        }
                                        font.pixelSize: 18
                                        color: netItem.isConnected ? Style.accentPink
                                             : netItem.isConnecting ? Style.accentAmber
                                             : Style.textSecondary
                                        fill: netItem.isConnected ? 1 : 0
                                        Layout.alignment: Qt.AlignVCenter

                                        Behavior on color { ColorAnimation { duration: Style.animFast } }
                                    }

                                    // Lock icon (separate, after wifi icon)
                                    MaterialIcon {
                                        text: "lock"
                                        font.pixelSize: 12
                                        color: Style.textDimmed
                                        visible: netItem.isSecured
                                        Layout.alignment: Qt.AlignVCenter
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
                                        visible: netItem.isKnown && !netItem.isConnected && !netHover.containsMouse
                                        fill: 1

                                        Behavior on opacity { NumberAnimation { duration: Style.animFast } }
                                    }

                                    // Forget button (hover-reveal on known networks)
                                    Rectangle {
                                        implicitWidth: 24
                                        implicitHeight: 24
                                        radius: Style.radiusFull
                                        color: forgetHover.containsMouse ? Qt.rgba(1, 0.27, 0.4, 0.15) : "transparent"
                                        visible: netItem.isKnown && !netItem.isConnected && netHover.containsMouse
                                        opacity: visible ? 1 : 0

                                        Behavior on color { ColorAnimation { duration: Style.animFast } }

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            text: "delete"
                                            font.pixelSize: 14
                                            color: forgetHover.containsMouse ? Style.colorUrgent : Style.textDimmed

                                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                                        }

                                        MouseArea {
                                            id: forgetHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NetworkManager.forgetNetwork(netItem.modelData.ssid)
                                        }
                                    }

                                    // Connecting spinner
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

    // ── SSID Tooltip ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: tooltipContent.opacity > 0
                && NetworkManager.tooltipScreen === modelData
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
                id: tooltipContent
                x: NetworkManager.tooltipX - width / 2
                y: Style.barHeight + Style.spaceSm
                width: Math.max(180, tooltipColumn.implicitWidth + Style.spaceXl * 2)
                height: tooltipColumn.implicitHeight + Style.spaceLg * 2

                opacity: NetworkManager.tooltipVisible ? 1 : 0
                scale: NetworkManager.tooltipVisible ? 1.0 : 0.92

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

                    // Neon top strip
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        radius: Style.radiusMd
                        color: Style.accentPink
                        opacity: 0.8
                    }

                    border.width: 1
                    border.color: Qt.rgba(1, 0.41, 0.71, 0.25)

                    ColumnLayout {
                        id: tooltipColumn
                        anchors.centerIn: parent
                        spacing: Style.spaceMd

                        // SSID name
                        RowLayout {
                            spacing: Style.spaceSm

                            MaterialIcon {
                                text: "wifi"
                                font.pixelSize: 16
                                color: Style.accentPink
                                fill: 1
                            }

                            StyledText {
                                text: NetworkManager.connectionName
                                font.pixelSize: Style.fontSizeMd
                                font.bold: true
                                color: Style.textPrimary
                            }
                        }

                        // Signal meter + percentage
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.spaceMd

                            // Full-width VU meter segments
                            Row {
                                spacing: 2
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                Repeater {
                                    model: 10

                                    Rectangle {
                                        required property int index
                                        property bool isLit: NetworkManager.signalStrength > index * 10

                                        width: (parent.width - 9 * parent.spacing) / 10
                                        height: 8
                                        radius: 1
                                        color: isLit ? Style.accentPink : Style.bgTertiary

                                        Behavior on color { ColorAnimation { duration: Style.animFast } }
                                    }
                                }
                            }

                            StyledText {
                                text: NetworkManager.signalStrength + "%"
                                font.pixelSize: Style.fontSizeSm
                                color: Style.textPrimary
                            }
                        }
                    }
                }
            }
        }
    }
}
