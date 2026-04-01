pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../Singleton"
import "components"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            color: Style.bgBar

            // Scale relative to 1080p baseline
            readonly property real sf: modelData.height / 1080

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Math.round(Style.barHeight * sf)

            // Left section
            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Math.round(Style.barPadding * panel.sf)
                spacing: Math.round(Style.spaceLg * panel.sf)

                Updates { sf: panel.sf; screen: panel.modelData; Layout.rightMargin: Math.round(Style.spaceSm * panel.sf) }
                Workspaces { sf: panel.sf; screen: panel.modelData }
                WindowTitle { sf: panel.sf }
                SysMon { sf: panel.sf; screen: panel.modelData }
                NetStat { sf: panel.sf }
            }

            // Center section
            RowLayout {
                anchors.centerIn: parent
                spacing: Math.round(Style.spaceSm * panel.sf)

                Media { sf: panel.sf; screen: panel.modelData }
            }

            // Right section
            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Math.round(Style.barPadding * panel.sf)
                spacing: Math.round(Style.spaceLg * panel.sf)

                SysTray { sf: panel.sf; panelWindow: panel; screen: panel.modelData }
                Bluetooth { sf: panel.sf; screen: panel.modelData }
                Volume { showIcon: true; sf: panel.sf; screen: panel.modelData }
                Network { sf: panel.sf; screen: panel.modelData }
                Keyboard { sf: panel.sf }
                Clipboard { sf: panel.sf; screen: panel.modelData }
                Weather { sf: panel.sf; screen: panel.modelData }
                Clock { sf: panel.sf; screen: panel.modelData }
                NotificationButton { sf: panel.sf; screen: panel.modelData }
                PowerMenu { sf: panel.sf; screen: panel.modelData }
            }
        }
    }
}
