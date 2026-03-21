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

                Workspaces { sf: panel.sf }
                WindowTitle { sf: panel.sf }
            }

            // Center section
            RowLayout {
                anchors.centerIn: parent
                spacing: Math.round(Style.spaceSm * panel.sf)

                Clock { sf: panel.sf }
            }

            // Right section
            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Math.round(Style.barPadding * panel.sf)
                spacing: Math.round(Style.spaceLg * panel.sf)

                Media { sf: panel.sf }
                SysTray { sf: panel.sf }
                Volume { showIcon: true; sf: panel.sf }
                Network { sf: panel.sf }
                Keyboard { sf: panel.sf }
                NotificationButton { sf: panel.sf; screen: panel.modelData }
                PowerMenu { sf: panel.sf }
            }
        }
    }
}
