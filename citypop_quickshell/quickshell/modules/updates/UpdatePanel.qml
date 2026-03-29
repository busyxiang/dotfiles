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
            property bool _open: UpdateState.visible && UpdateState.screen === modelData
            visible: UpdateState.visible || card.opacity > 0
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
                onClicked: UpdateState.visible = false
            }

            // --- Dropdown Card ---
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: Math.round(Style.spaceMd * panel.sf)
                anchors.leftMargin: Math.round(Style.spaceMd * panel.sf)
                width: 380
                height: UpdateState.totalCount > 0 ? Math.min(500, parent.height * 0.7) : 150
                color: Style.bgSecondary
                radius: Style.radiusLg
                border.width: 1
                border.color: Style.bgTertiary
                clip: true

                opacity: panel._open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: panel._open ? 0 : -8
                    Behavior on y { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                }

                NeonStrip {}

                MouseArea { anchors.fill: parent }

                // Refresh button
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: closeBtn.left
                    anchors.topMargin: Style.spaceMd
                    anchors.rightMargin: Style.spaceSm
                    z: 2
                    width: 28; height: 28
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
                    }

                    RotationAnimation {
                        id: refreshSpin
                        target: refreshIcon
                        from: 0; to: 360
                        duration: 600
                        easing.type: Easing.InOutCubic
                    }

                    MouseArea {
                        id: refreshHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            refreshSpin.start()
                            UpdateState.resetRetry()
                            UpdateState.checkUpdates()
                        }
                    }
                }

                CloseButton {
                    id: closeBtn
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: Style.spaceMd
                    anchors.rightMargin: Style.spaceMd
                    z: 2
                    onClicked: UpdateState.visible = false
                }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: Style.spaceXl
                    spacing: Style.spaceLg

                    // --- Header ---
                    RowLayout {
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "system_update_alt"
                            font.pixelSize: 20
                            color: Style.accentPink
                            fill: 1
                        }

                        StyledText {
                            text: {
                                if (UpdateState.checking) return "Checking for updates…"
                                if (UpdateState.checkError) return "Failed to check updates"
                                if (UpdateState.retrying) return "Retrying…"
                                if (UpdateState.totalCount === 0) return "System is up to date"
                                return UpdateState.totalCount + " update" + (UpdateState.totalCount > 1 ? "s" : "") + " available"
                            }
                            font.pixelSize: Style.fontSizeLg
                            font.bold: true
                            color: {
                                if (UpdateState.checkError) return Style.accentAmber
                                if (UpdateState.retrying) return Style.textDimmed
                                if (UpdateState.totalCount > 0) return Style.textPrimary
                                return Style.colorGood
                            }
                        }
                    }

                    // --- Neon Divider ---
                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Style.accentPink
                        opacity: 0.6
                    }

                    // --- Scrollable package list ---
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: pkgList.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: pkgList
                            width: parent.width
                            spacing: Style.spaceMd

                            // --- Pacman section (collapsible) ---
                            ColumnLayout {
                                id: pacSection
                                Layout.fillWidth: true
                                spacing: 0
                                visible: UpdateState.pacmanUpdates.length > 0
                                property bool collapsed: false

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: pacHeader.implicitHeight + Style.spaceMd * 2
                                    radius: Style.radiusMd
                                    color: pacHeaderArea.containsMouse ? Style.bgTertiary : Style.bgPrimary
                                    Behavior on color { ColorAnimation { duration: Style.animFast } }

                                    MouseArea {
                                        id: pacHeaderArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: pacSection.collapsed = !pacSection.collapsed
                                    }

                                    RowLayout {
                                        id: pacHeader
                                        anchors.fill: parent
                                        anchors.margins: Style.spaceMd
                                        spacing: Style.spaceSm

                                        MaterialIcon {
                                            text: pacSection.collapsed ? "expand_more" : "expand_less"
                                            font.pixelSize: 16
                                            fill: 0
                                            color: pacHeaderArea.containsMouse ? Style.textSecondary : Style.textDimmed
                                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                                        }

                                        StyledText {
                                            text: "pacman"
                                            font.pixelSize: Style.fontSizeSm
                                            font.bold: true
                                            color: Style.accentPink
                                        }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            implicitWidth: pacCountLabel.implicitWidth + Style.spaceMd * 2
                                            implicitHeight: pacCountLabel.implicitHeight + Style.spaceSm
                                            radius: Style.radiusFull
                                            color: Style.bgTertiary

                                            StyledText {
                                                id: pacCountLabel
                                                anchors.centerIn: parent
                                                text: UpdateState.pacmanUpdates.length
                                                color: Style.textSecondary
                                                font.pixelSize: 11
                                            }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    visible: !pacSection.collapsed

                                    Repeater {
                                        model: UpdateState.pacmanUpdates

                                        Rectangle {
                                            id: pacPkg
                                            required property var modelData
                                            Layout.fillWidth: true
                                            implicitHeight: pacRow.implicitHeight + Style.spaceMd * 2
                                            radius: Style.radiusSm
                                            color: pacPkgHover.containsMouse ? Style.bgTertiary : "transparent"
                                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                                            RowLayout {
                                                id: pacRow
                                                anchors.fill: parent
                                                anchors.leftMargin: Style.spaceXl
                                                anchors.rightMargin: Style.spaceMd
                                                spacing: Style.spaceSm

                                                // Critical indicator
                                                MaterialIcon {
                                                    visible: pacPkg.modelData.critical
                                                    text: "warning"
                                                    font.pixelSize: 12
                                                    color: Style.accentAmber
                                                    fill: 1
                                                }

                                                StyledText {
                                                    text: pacPkg.modelData.name
                                                    font.pixelSize: Style.fontSizeSm
                                                    color: pacPkg.modelData.critical ? Style.accentAmber : Style.textPrimary
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }

                                                StyledText {
                                                    text: pacPkg.modelData.oldVer
                                                    font.pixelSize: 11
                                                    color: Style.textSecondary
                                                }

                                                MaterialIcon {
                                                    text: "arrow_forward"
                                                    font.pixelSize: 12
                                                    color: Style.textDimmed
                                                    fill: 0
                                                }

                                                StyledText {
                                                    text: pacPkg.modelData.newVer
                                                    font.pixelSize: 11
                                                    color: Style.accentPink
                                                }
                                            }

                                            MouseArea {
                                                id: pacPkgHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                            }
                                        }
                                    }
                                }
                            }

                            // --- AUR section (collapsible) ---
                            ColumnLayout {
                                id: aurSection
                                Layout.fillWidth: true
                                spacing: 0
                                visible: UpdateState.aurUpdates.length > 0
                                property bool collapsed: false

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: aurHeader.implicitHeight + Style.spaceMd * 2
                                    radius: Style.radiusMd
                                    color: aurHeaderArea.containsMouse ? Style.bgTertiary : Style.bgPrimary
                                    Behavior on color { ColorAnimation { duration: Style.animFast } }

                                    MouseArea {
                                        id: aurHeaderArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: aurSection.collapsed = !aurSection.collapsed
                                    }

                                    RowLayout {
                                        id: aurHeader
                                        anchors.fill: parent
                                        anchors.margins: Style.spaceMd
                                        spacing: Style.spaceSm

                                        MaterialIcon {
                                            text: aurSection.collapsed ? "expand_more" : "expand_less"
                                            font.pixelSize: 16
                                            fill: 0
                                            color: aurHeaderArea.containsMouse ? Style.textSecondary : Style.textDimmed
                                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                                        }

                                        StyledText {
                                            text: "AUR"
                                            font.pixelSize: Style.fontSizeSm
                                            font.bold: true
                                            color: Style.accentPurple
                                        }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            implicitWidth: aurCountLabel.implicitWidth + Style.spaceMd * 2
                                            implicitHeight: aurCountLabel.implicitHeight + Style.spaceSm
                                            radius: Style.radiusFull
                                            color: Style.bgTertiary

                                            StyledText {
                                                id: aurCountLabel
                                                anchors.centerIn: parent
                                                text: UpdateState.aurUpdates.length
                                                color: Style.textSecondary
                                                font.pixelSize: 11
                                            }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    visible: !aurSection.collapsed

                                    Repeater {
                                        model: UpdateState.aurUpdates

                                        Rectangle {
                                            id: aurPkg
                                            required property var modelData
                                            Layout.fillWidth: true
                                            implicitHeight: aurRow.implicitHeight + Style.spaceMd * 2
                                            radius: Style.radiusSm
                                            color: aurPkgHover.containsMouse ? Style.bgTertiary : "transparent"
                                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                                            RowLayout {
                                                id: aurRow
                                                anchors.fill: parent
                                                anchors.leftMargin: Style.spaceXl
                                                anchors.rightMargin: Style.spaceMd
                                                spacing: Style.spaceSm

                                                MaterialIcon {
                                                    visible: aurPkg.modelData.critical
                                                    text: "warning"
                                                    font.pixelSize: 12
                                                    color: Style.accentAmber
                                                    fill: 1
                                                }

                                                StyledText {
                                                    text: aurPkg.modelData.name
                                                    font.pixelSize: Style.fontSizeSm
                                                    color: aurPkg.modelData.critical ? Style.accentAmber : Style.textPrimary
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }

                                                StyledText {
                                                    text: aurPkg.modelData.oldVer
                                                    font.pixelSize: 11
                                                    color: Style.textSecondary
                                                }

                                                MaterialIcon {
                                                    text: "arrow_forward"
                                                    font.pixelSize: 12
                                                    color: Style.textDimmed
                                                    fill: 0
                                                }

                                                StyledText {
                                                    text: aurPkg.modelData.newVer
                                                    font.pixelSize: 11
                                                    color: Style.accentPurple
                                                }
                                            }

                                            MouseArea {
                                                id: aurPkgHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                            }
                                        }
                                    }
                                }
                            }

                            // --- No updates message ---
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                spacing: Style.spaceMd
                                visible: !UpdateState.checking && !UpdateState.checkError && UpdateState.totalCount === 0

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "check_circle"
                                    font.pixelSize: 36
                                    color: Style.colorGood
                                    fill: 1
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "All packages are up to date"
                                    font.pixelSize: Style.fontSizeSm
                                    color: Style.textDimmed
                                }
                            }

                            // --- Error state ---
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                spacing: Style.spaceMd
                                visible: UpdateState.checkError || UpdateState.retrying

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "error_outline"
                                    font.pixelSize: 36
                                    color: Style.accentAmber
                                    fill: 0
                                    visible: UpdateState.checkError
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: {
                                        if (UpdateState.checkError) return "Failed to check for updates"
                                        if (UpdateState.retrying) return "Retrying in " + Math.ceil(UpdateState._retryDelays[Math.max(0, UpdateState._retryCount - 1)] / 60000) + "m… (attempt " + UpdateState._retryCount + "/" + UpdateState._maxRetries + ")"
                                        return ""
                                    }
                                    font.pixelSize: Style.fontSizeMd
                                    color: UpdateState.checkError ? Style.accentAmber : Style.textDimmed
                                }

                                Rectangle {
                                    visible: UpdateState.checkError
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: updateRetryRow.implicitWidth + Style.spaceXl * 2
                                    implicitHeight: 28
                                    radius: Style.radiusFull
                                    color: updateRetryHover.containsMouse ? Style.bgTertiary : "transparent"
                                    border.width: 1
                                    border.color: Style.accentPink
                                    Behavior on color { ColorAnimation { duration: Style.animFast } }

                                    RowLayout {
                                        id: updateRetryRow
                                        anchors.centerIn: parent
                                        spacing: Style.spaceSm

                                        MaterialIcon {
                                            text: "refresh"
                                            font.pixelSize: 14
                                            color: Style.accentPink
                                            fill: 0
                                        }
                                        StyledText {
                                            text: "Retry"
                                            font.pixelSize: Style.fontSizeSm
                                            color: Style.accentPink
                                        }
                                    }

                                    MouseArea {
                                        id: updateRetryHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            UpdateState.resetRetry()
                                            UpdateState.checkUpdates()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // --- Update All button ---
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: Style.radiusMd
                        color: Style.accentPink
                        opacity: updateBtnHover.containsMouse ? 0.85 : 1.0
                        Behavior on opacity { NumberAnimation { duration: Style.animFast } }
                        visible: UpdateState.totalCount > 0 && !UpdateState.updating

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Style.spaceMd

                            MaterialIcon {
                                text: "terminal"
                                font.pixelSize: 18
                                color: Style.bgPrimary
                                fill: 1
                            }

                            StyledText {
                                text: "Update all"
                                font.pixelSize: Style.fontSizeMd
                                font.bold: true
                                color: Style.bgPrimary
                            }
                        }

                        MouseArea {
                            id: updateBtnHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (UpdateState.updating) return
                                UpdateState.runUpdate()
                                UpdateState.visible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
