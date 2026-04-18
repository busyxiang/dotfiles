pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Singleton"
import "../../common"

Scope {
    // Menu data source — re-created when menuHandle changes
    QsMenuOpener {
        id: menuOpener
        menu: TrayMenuState.menuHandle
    }

    Variants {
        model: Quickshell.screens

        DropdownPanel {
            id: panel
            required property var modelData
            screen: modelData

            stateOpen: TrayMenuState.visible
            stateScreen: TrayMenuState.screen
            onDismissed: TrayMenuState.close()

            cardWidth: 220
            cardPadding: Style.spaceMd
            cardRadius: Style.radiusMd
            anchorMode: "widget"
            widgetCenterX: TrayMenuState.anchorX

            ColumnLayout {
                id: menuCol
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                Repeater {
                    model: menuOpener.children

                    delegate: Item {
                        id: menuEntry
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: visible ? (modelData.isSeparator ? sep.height : entryRect.height) : 0
                        visible: modelData.isSeparator || (modelData.text !== "")

                        // ── Separator ──
                        Rectangle {
                            id: sep
                            visible: menuEntry.modelData.isSeparator
                            width: parent.width
                            height: visible ? Style.spaceMd + 1 : 0
                            color: "transparent"

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width
                                height: 1
                                color: Style.accentPink
                                opacity: 0.3
                            }
                        }

                        // ── Menu Item ──
                        Rectangle {
                            id: entryRect
                            visible: !menuEntry.modelData.isSeparator
                            width: parent.width
                            height: visible ? 32 : 0
                            radius: Style.radiusSm
                            color: entryHover.containsMouse && menuEntry.modelData.enabled
                                ? Style.pinkHover : "transparent"
                            opacity: menuEntry.modelData.enabled ? 1.0 : 0.4

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Style.spaceMd
                                anchors.rightMargin: Style.spaceMd
                                spacing: Style.spaceMd

                                // Check/radio indicator
                                MaterialIcon {
                                    readonly property int btnType: Number(menuEntry.modelData.buttonType)
                                    visible: btnType > 0
                                    text: {
                                        if (menuEntry.modelData.checkState === Qt.Checked)
                                            return btnType === 1 ? "check_box" : "radio_button_checked"
                                        return btnType === 1 ? "check_box_outline_blank" : "radio_button_unchecked"
                                    }
                                    font.pixelSize: 14
                                    color: menuEntry.modelData.checkState === Qt.Checked
                                        ? Style.accentPink : Style.textDimmed
                                }

                                StyledText {
                                    text: menuEntry.modelData.text
                                    font.pixelSize: Style.fontSizeSm
                                    color: entryHover.containsMouse && menuEntry.modelData.enabled
                                        ? Style.accentPink : Style.textSecondary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                }

                                // Submenu arrow
                                MaterialIcon {
                                    visible: menuEntry.modelData.hasChildren
                                    text: "chevron_right"
                                    font.pixelSize: 14
                                    color: entryHover.containsMouse ? Style.accentPink : Style.textDimmed

                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                }
                            }

                            MouseArea {
                                id: entryHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: menuEntry.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (!menuEntry.modelData.enabled) return
                                    if (menuEntry.modelData.hasChildren) {
                                        // TODO: submenu support
                                        return
                                    }
                                    menuEntry.modelData.triggered()
                                    TrayMenuState.close()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
