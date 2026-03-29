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
            property bool _open: ClipboardState.visible && ClipboardState.screen === modelData
            visible: ClipboardState.visible || card.opacity > 0
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore
            margins.top: Math.round(Style.barHeight * panel.sf)
            focusable: true

            MouseArea {
                anchors.fill: parent
                onClicked: ClipboardState.visible = false
            }

            // --- Copied toast ---
            property bool _showCopied: false
            Rectangle {
                id: copiedToast
                anchors.bottom: card.bottom
                anchors.horizontalCenter: card.horizontalCenter
                anchors.bottomMargin: Style.spaceLg
                z: 10
                width: copiedRow.implicitWidth + Style.spaceXl * 2
                height: copiedRow.implicitHeight + Style.spaceMd * 2
                radius: Style.radiusFull
                color: Style.bgTertiary
                border.width: 1
                border.color: Style.pinkBorder
                opacity: panel._showCopied ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.animFast } }

                RowLayout {
                    id: copiedRow
                    anchors.centerIn: parent
                    spacing: Style.spaceSm

                    MaterialIcon {
                        text: "check"
                        font.pixelSize: 14
                        color: Style.colorGood
                        fill: 1
                    }

                    StyledText {
                        text: "Copied"
                        font.pixelSize: Style.fontSizeSm
                        color: Style.textPrimary
                    }
                }
            }

            Timer {
                id: copiedTimer
                interval: 1000
                onTriggered: panel._showCopied = false
            }

            function showCopied() {
                _showCopied = true
                copiedTimer.restart()
            }

            // --- Dropdown Card ---
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Math.round(Style.spaceMd * panel.sf)
                anchors.rightMargin: Math.round((Style.spaceMd + 200) * panel.sf)
                width: 360
                height: ClipboardState.entryCount > 0 ? Math.min(480, parent.height * 0.7) : 150
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

                // Clear all button
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: closeBtn.left
                    anchors.topMargin: Style.spaceMd
                    anchors.rightMargin: Style.spaceSm
                    z: 2
                    width: 28; height: 28
                    radius: Style.radiusFull
                    color: clearHover.containsMouse ? Style.urgentBg : "transparent"
                    visible: ClipboardState.entryCount > 0
                    Behavior on color { ColorAnimation { duration: Style.animFast } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "delete_sweep"
                        font.pixelSize: 16
                        color: clearHover.containsMouse ? Style.colorUrgent : Style.textDimmed
                        Behavior on color { ColorAnimation { duration: Style.animFast } }
                    }

                    MouseArea {
                        id: clearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ClipboardState.clearAll()
                    }
                }

                CloseButton {
                    id: closeBtn
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: Style.spaceMd
                    anchors.rightMargin: Style.spaceMd
                    z: 2
                    onClicked: ClipboardState.visible = false
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
                            text: "content_paste"
                            font.pixelSize: 20
                            color: Style.accentPink
                            fill: 1
                        }

                        StyledText {
                            text: {
                                if (ClipboardState.loading) return "Loading…"
                                if (ClipboardState.entryCount === 0) return "Clipboard is empty"
                                return ClipboardState.entryCount + " item" + (ClipboardState.entryCount > 1 ? "s" : "")
                            }
                            font.pixelSize: Style.fontSizeLg
                            font.bold: true
                            color: ClipboardState.entryCount === 0 ? Style.textDimmed : Style.textPrimary
                        }
                    }

                    // --- Search Bar ---
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: searchRow.implicitHeight + Style.spaceMd * 2
                        radius: Style.radiusMd
                        color: searchInput.activeFocus ? Qt.darker(Style.bgTertiary, 1.1) : Style.bgTertiary
                        border.width: searchInput.activeFocus ? 1 : 0
                        border.color: Style.pinkBorder
                        visible: ClipboardState.entryCount > 0
                        Behavior on color { ColorAnimation { duration: Style.animFast } }

                        RowLayout {
                            id: searchRow
                            anchors.fill: parent
                            anchors.margins: Style.spaceMd
                            spacing: Style.spaceSm

                            MaterialIcon {
                                text: "search"
                                font.pixelSize: 16
                                color: searchInput.activeFocus ? Style.accentPink : Style.textDimmed
                                fill: 0
                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                color: Style.textPrimary
                                selectionColor: Style.accentPink
                                selectedTextColor: Style.bgPrimary
                                font.family: "CaskaydiaCove Nerd Font"
                                font.pixelSize: Style.fontSizeSm
                                clip: true
                                focus: panel._open
                                onTextChanged: ClipboardState.searchQuery = text
                                Keys.onEscapePressed: ClipboardState.visible = false

                                // Placeholder
                                StyledText {
                                    anchors.fill: parent
                                    text: "Search clipboard…"
                                    font.pixelSize: Style.fontSizeSm
                                    color: Style.textDimmed
                                    visible: searchInput.text === "" && !searchInput.activeFocus
                                }
                            }

                            // Clear search
                            Rectangle {
                                visible: searchInput.text !== ""
                                implicitWidth: 18; implicitHeight: 18
                                radius: Style.radiusFull
                                color: clearSearchHover.containsMouse ? Style.bgSecondary : "transparent"
                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "close"
                                    font.pixelSize: 12
                                    color: clearSearchHover.containsMouse ? Style.textPrimary : Style.textDimmed
                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                }

                                MouseArea {
                                    id: clearSearchHover
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        searchInput.text = ""
                                        searchInput.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }

                    // --- Neon Divider ---
                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Style.accentPink
                        opacity: 0.6
                        visible: ClipboardState.entryCount > 0
                    }

                    // --- Empty state ---
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: ClipboardState.entryCount === 0 && !ClipboardState.loading

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Style.spaceMd

                            MaterialIcon {
                                Layout.alignment: Qt.AlignHCenter
                                text: "content_paste_off"
                                font.pixelSize: 36
                                color: Style.textDimmed
                                fill: 1
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Copy something to get started"
                                font.pixelSize: Style.fontSizeSm
                                color: Style.textDimmed
                            }
                        }
                    }

                    // --- No search results ---
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: ClipboardState.entryCount > 0 && ClipboardState.filtered.length === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Style.spaceMd

                            MaterialIcon {
                                Layout.alignment: Qt.AlignHCenter
                                text: "search_off"
                                font.pixelSize: 36
                                color: Style.textDimmed
                                fill: 1
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No matching entries"
                                font.pixelSize: Style.fontSizeSm
                                color: Style.textDimmed
                            }
                        }
                    }

                    // --- Scrollable entry list ---
                    Flickable {
                        id: entryFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: entryList.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        visible: ClipboardState.filtered.length > 0

                        // Scrollbar
                        Rectangle {
                            parent: entryFlick
                            anchors.right: parent.right
                            anchors.rightMargin: 1
                            y: entryFlick.contentHeight > 0
                                ? entryFlick.contentY / entryFlick.contentHeight * entryFlick.height
                                : 0
                            width: 3
                            height: entryFlick.contentHeight > 0
                                ? Math.max(20, entryFlick.height / entryFlick.contentHeight * entryFlick.height)
                                : 0
                            radius: Style.radiusFull
                            color: Style.accentPink
                            opacity: entryFlick.moving ? 0.6 : 0
                            Behavior on opacity { NumberAnimation { duration: Style.animNormal } }
                            z: 10
                            visible: entryFlick.contentHeight > entryFlick.height
                        }

                        ColumnLayout {
                            id: entryList
                            width: parent.width
                            spacing: Style.spaceSm

                            Repeater {
                                model: ClipboardState.filtered

                                Rectangle {
                                    id: entryRow
                                    required property var modelData
                                    required property int index

                                    readonly property bool isHovered: entryHover.containsMouse || deleteHover.containsMouse

                                    Layout.fillWidth: true
                                    implicitHeight: entryContent.implicitHeight + Style.spaceMd * 2
                                    radius: Style.radiusMd
                                    color: isHovered ? Style.bgTertiary : "transparent"
                                    Behavior on color { ColorAnimation { duration: Style.animFast } }

                                    RowLayout {
                                        id: entryContent
                                        anchors.fill: parent
                                        anchors.margins: Style.spaceMd
                                        spacing: Style.spaceMd

                                        // Type icon (text entries only)
                                        MaterialIcon {
                                            text: "text_snippet"
                                            font.pixelSize: 16
                                            color: Style.textDimmed
                                            fill: 0
                                            Layout.alignment: Qt.AlignTop
                                            visible: !entryRow.modelData.isImage
                                        }

                                        // Image thumbnail
                                        Rectangle {
                                            visible: entryRow.modelData.isImage
                                            Layout.preferredWidth: 48
                                            Layout.preferredHeight: 48
                                            Layout.alignment: Qt.AlignTop
                                            radius: Style.radiusSm
                                            color: Style.bgTertiary
                                            clip: true
                                            border.width: 1
                                            border.color: entryRow.isHovered ? Style.pinkBorder : Style.bgTertiary

                                            Image {
                                                id: thumbImg
                                                anchors.fill: parent
                                                anchors.margins: 1
                                                source: entryRow.modelData.imagePath || ""
                                                fillMode: Image.PreserveAspectCrop
                                                sourceSize.width: 96
                                                sourceSize.height: 96
                                                asynchronous: true
                                                cache: true
                                            }

                                            // Fallback icon while loading
                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                text: "image"
                                                font.pixelSize: 20
                                                color: Style.accentPurple
                                                fill: 1
                                                visible: thumbImg.status !== Image.Ready
                                            }
                                        }

                                        // Content preview
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: entryRow.modelData.isImage ? "Image" : entryRow.modelData.text
                                            font.pixelSize: Style.fontSizeSm
                                            color: entryRow.isHovered
                                                ? (entryRow.modelData.isImage ? Style.accentPurple : Style.textPrimary)
                                                : (entryRow.modelData.isImage ? Style.accentPurple : Style.textSecondary)
                                            font.italic: entryRow.modelData.isImage
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: 3
                                            elide: Text.ElideRight
                                            Behavior on color { ColorAnimation { duration: Style.animFast } }
                                        }

                                        // Delete button
                                        Rectangle {
                                            visible: entryRow.isHovered
                                            Layout.preferredWidth: 22
                                            Layout.preferredHeight: 22
                                            Layout.alignment: Qt.AlignTop
                                            radius: Style.radiusFull
                                            color: deleteHover.containsMouse ? Style.urgentBg : "transparent"
                                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                text: "close"
                                                font.pixelSize: 14
                                                color: deleteHover.containsMouse ? Style.colorUrgent : Style.textDimmed
                                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                                            }

                                            MouseArea {
                                                id: deleteHover
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ClipboardState.deleteEntry(entryRow.modelData.id)
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: entryHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        z: -1
                                        onClicked: {
                                            ClipboardState.copyEntry(entryRow.modelData.id)
                                            panel.showCopied()
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
}
